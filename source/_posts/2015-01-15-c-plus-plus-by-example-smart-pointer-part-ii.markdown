---
layout: post
title: "C++ by Example: Smart Pointer Part II"
date: 2015-01-15 08:13:47 -0800
categories: [C++, C++-By-Example, Coding]
comments: true
sharing: true
footer: true
---
So in the previous article I covered a basic `unique` pointer where the smart pointer retained sole ownership of the pointer. The other common smart pointer we encounter is the `shared` pointer (SP). In this case the ownership of the pointer is shared across multiple instances of SP and the pointer is only released (deleted) when all SP instances have been destroyed.

So not only do we have to store the pointer but we need a mechanism for keeping track of all the SP instances that are sharing ownership of the pointer. When the last SP instance is destroyed it also deletes the pointer (The last owner cleans up. A similar principle to the last one to leave the room turns out the lights).
```cpp Shared Pointer contextual destructor

    namespace ThorsAnvil
    {
        template<typename T>
        class SP
        {
            T*  data;
            public:
                ~SP()
                {
                    if (amITheLastOwner())
                    {
                        delete data;
                    }
                }
        };
    }
```
There are two major techniques for tracking the shared owners of a pointer:

<ol>
  <li>Keep a count:</li>
  <ul>
    <li>When the count is 1 you are the last owner.</li>
    <li>This is a very simple and logical technique. You have a shared counter that is incremented/decrement as SP instances take/release ownership of the pointer. The disadvantages are that you need dynamically allocated memory that must be managed and in a threaded environment you need to serialize accesses to counter.</li>
  </ul>
  <li>Use a linked list of the owners:</li>
  <ul>
    <li>When you are the only member of the list you are the last owner.</li>
    <li>When a SP instance take/releases ownership of the pointer they are added/removed to/from the linked list. This is slightly more complex as you need to maintain a circular linked list (for O(1)). The advantage is that you don't need to manage any separate memory for the count (A SP instance simply points at the next SP instance in the chain) and in a threaded environment adding/removing a shared pointer need not always be serialized (though you will still need to lock your neighbors to enforce integrity).</li>
  </ul>
</ol>

###Shared Count
This is basically the technique used by the [`std::shared_ptr`](http://en.cppreference.com/w/cpp/memory/shared_ptr) (though they store slightly more than the count to try and improve efficiency see [`std::make_shared`](http://en.cppreference.com/w/cpp/memory/shared_ptr/make_shared)).

The main mistake I see from beginners is not using dynamically allocated counter (ie they keep the counter in the SP object). You **must** dynamically allocate memory for the counter so that it can be shared by all SP instances (you can not tell how many there will be or the order in which they will be deleted). 

You must also serialize access to this counter to make sure that in a threaded environment the count is correctly maintained. In the following article for simplicity I will only consider single threaded environments. But with C++11 and `std::atomic` that should be relatively simple.
```cpp First Try

    namespace ThorsAnvil
    {
        template<typename T>
        class SP
        {
            T*      data;
            int*    count;
            public:
                // Remember from ThorsAnvil::UP that the constructor
                // needs to be explicit to prevent the compiler creating
                // temporary objects on the fly.
                explicit SP(T* data)
                    : data(data)
                    , count(new int(1))
                {}
                ~SP()
                {
                    --(*count);
                    if (*count == 0)
                    {
                        delete data;
                    }
                }
                // Remember from ThorsAnvil::UP that we need to make sure we
                // obey the rule of three. So we will implement the copy
                // constructor and assignment operator.
                SP(SP const& copy)
                    : data(copy.data)
                    , count(copy.count)
                {
                    ++(*count);
                }
                SP& operator=(SP const& rhs)
                {
                    if (&rhs == this)
                    {
                         // return early on self assignment.
                         return *this;
                    }
                    T*   oldData  = data;
                    int* oldCount = count;
                    
                    // now we do an exception safe transfer;
                    data  = rhs.data;
                    count = rhs.count;
                    ++(*count);

                    --(*oldCount);
                    if (*oldCount == 0)
                    {
                        delete oldData;
                    }
                }
                // Const correct access owned object
                T* operator->() const {return data;}
                T& operator*()  const {return *data;}
                
                // Access to smart pointer state
                T* get()        const {return data;}
                operator bool() const {return data;}
        };
    }
```
##Problem 1: Potential Constructor Failure
When a developer (attempts) to create a SP they are handing over ownership of the pointer to the SP instance. Once the constructor starts there is an expectation by the developer that no further checks are needed. But there is a problem with the code as written.

In C++ memory allocation through new does not fail (unlike C where `malloc()` can return a Null on failure). In C++ a failure to allocate memory via the standard new generates a `std::bad_alloc` exception. Additionally if we throw an exception out of a constructor the destructor will never be called (the destructor is only called on fully formed objects) when the instances lifespan ends.

So if an exception is thrown during construction (and thus the destructor will not be called) we must assume responsibility for making sure that pointer is deleted before the exception escapes the constructor, otherwise there will be a resultant leak of the pointer.
```cpp Constructor takes responsibility for pointer

    namespace ThorsAnvil
    {
             explicit SP::SP(T* data)
                    : data(data)
                    , count(new (std::nothorw) int(1)) // use the no throw version of new.
                {
                    // Check if the pointer correctly allocated
                    if (count == nullptr)
                    {
                        // If we failed then delete the pointer
                        // and throw the exception.
                        delete data;
                        throw std::bad_alloc();
                    }
                }
                // or
                explicit SP::SP(T* data)
                try
                    : data(data)
                    , count(new int(1))
                {}
                // The rarely used catch for exceptions in argument lists.
                catch(...)
                {
                    // If we failed because of an exception
                    // delete the pointer and rethrow the exception.
                    delete data;
                    throw;
                }

    }
```
##Problem 2: DRY up the Assignment
Currently the assignment operators are exception safe and conform to the strong exception guarantee so there is no real problem here. **But** there seems to be a lot of duplicated code in the class.
```cpp Closer look at assignment start:6 mark:8-9
                SP& operator=(SP const& rhs)
                {
                    if (&rhs == this)
                    {
                         // return early on self assignment.
                         return *this;
                    }
                    T*   oldData  = data;
                    int* oldCount = count;
                    
                    // now we do an exception safe transfer;
                    data  = rhs.data;
                    count = rhs.count;
                    ++(*count);

                    --(*oldCount);
                    if (*oldCount == 0)
                    {
                        delete oldData;
                    }
                }
```
##Fixed First Try
So given the problems described above we can update our implementation to compensate for these issues:
```cpp Fixed First Try

    namespace ThorsAnvil
    {
        template<typename T>
        class SP
        {
            T*      data;
            int*    count;
            public:
                // Explicit constructor
                explicit SP(T* data)
                try
                    : data(data)
                    , count(new int(1))
                {}
                catch(...)
                {
                    // If we failed because of an exception
                    // delete the pointer and rethrow the exception.
                    delete data;
                    throw;
                }
                ~SP()
                {
                    --*count;
                    if (*count == 0)
                    {
                        delete data;
                    }
                }
                SP(SP const& copy)
                    : data(copy.data)
                    , count(copy.count)
                {
                    ++(*count);
                }
                // Use the copy and swap idiom
                // It works perfectly for this situation.
                SP& operator=(SP rhs)
                {
                    rhs.swap(*this);
                    return *this;
                }
                SP& operator=(T* newData)
                {
                    SP tmp(newData);
                    tmp.swap(*this);
                    return *this;
                }
                // Always good to have a swap function
                // Make sure it is noexcept
                void swap(SP& other) noexcept
                {
                    std::swap(data,  other.data);
                    std::swap(count, other.count);
                }
                // Const correct access owned object
                T* operator->() const {return data;}
                T& operator*()  const {return *data;}
                
                // Access to smart pointer state
                T* get()        const {return data;}
                operator bool() const {return data;}
            };
    }
```
##Summary
So in this second post we have looked at two implementation techniques of shared pointer and summarized the common problems problems usually overlooked. In the next article I want to look at a couple of other issues common to both types of smart pointers.
