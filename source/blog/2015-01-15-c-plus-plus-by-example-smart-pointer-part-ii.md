---
layout: post
title: "Smart-Pointer - Shared Pointer"
date: 2015-01-15 08:13:47 -0800
comments: true
categories: [C++, Smart-Pointer, C++-By-Example, Coding]
series: Smart-Pointer
tags: Smart-Pointer
sharing: true
footer: true
subtitle: C++ By Example
author: Loki Astari, (C)2013
description: C++ By Example. Part 2 Shared Pointer. In this article we cover some of the common implementation techniques used for a smart pointer that provides shared ownership of a resource.
---
So in [the previous article](https://lokiastari.com/blog/2014/12/30/c-plus-plus-by-example-smart-pointer/) I covered a basic `unique` pointer where the smart pointer retained sole ownership of the pointer. The other common smart pointer we encounter is the `shared` pointer (SP). In this case the ownership of the pointer is shared across multiple instances of SP and the pointer is only released (deleted) when all SP instances have been destroyed.

So not only do we have to store the pointer but we need a mechanism for keeping track of all the SP instances that are sharing ownership of the pointer. When the last SP instance is destroyed it also deletes the pointer (The last owner cleans up. A similar principle to the last one to leave the room turns out the lights).

Shared Pointer contextual destructor
```c
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
    <li>When a SP instance take/releases ownership of the pointer they are added/removed to/from the linked list. This is slightly more complex as you need to maintain a circular linked list (for O(1)). The advantage is that you do not need to manage any separate memory for the count (A SP instance simply points at the next SP instance in the chain) and in a threaded environment adding/removing a shared pointer need not always be serialized (though you will still need to lock your neighbors to enforce integrity).</li>
  </ul>
</ol>

## Shared Count
The easier of the two to implement correctly is the list version. There are no real gotchas (that I have seen). Though people do struggle with insertion and removal of a link from a circular list. I have another article planned for that at some point so I will cover it then.

The *Shared Count* is basically the technique used by the [`std::shared_ptr`](http://en.cppreference.com/w/cpp/memory/shared_ptr) (though they store slightly more than the count to try and improve efficiency see [`std::make_shared`](http://en.cppreference.com/w/cpp/memory/shared_ptr/make_shared)).

The main mistake I see from beginners is not using dynamically allocated counter (i.e. they keep the counter in the SP object). You **must** dynamically allocate memory for the counter so that it can be shared by all SP instances (you can not tell how many there will be or the order in which they will be deleted).

You must also serialize access to this counter to make sure that in a threaded environment the count is correctly maintained. In the first version for simplicity I will only consider single threaded environments and thus synchronization is not required.

First Try
```c
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
                // Keep a copy of the old data
                T*   oldData  = data;
                int* oldCount = count;

                // now we do an exception safe transfer;
                data  = rhs.data;
                count = rhs.count;

                // Update the counters
                ++(*count);
                --(*oldCount);

                // Finally delete the old pointer if required.
                if (*oldCount == 0)
                {
                    delete oldData;
                }
            }
            // Const correct access owned object
            T* operator->() const {return data;}
            T& operator*()  const {return *data;}

            // Access to smart pointer state
            T* get()                 const {return data;}
            explicit operator bool() const {return data;}
    };
}
```
### Problem 1: Potential Constructor Failure
When a developer (attempts) to create a SP they are handing over ownership of the pointer to the SP instance. Once the constructor starts there is an expectation by the developer that no further checks are needed. But there is a problem with the code as written.

In C++ memory allocation through new does not fail (unlike C where `malloc()` can return a Null on failure). In C++ a failure to allocate memory via the standard new generates a `std::bad_alloc` exception. Additionally if we throw an exception out of a constructor the destructor will never be called (the destructor is only called on fully formed objects) when the instance's lifespan ends.

So if an exception is thrown during construction (and thus the destructor will not be called) we must assume responsibility for making sure that pointer is deleted before the exception escapes the constructor, otherwise there will be a resultant leak of the pointer.

Constructor takes responsibility for pointer
```c
namespace ThorsAnvil
{
     .....
             explicit SP(T* data)
                : data(data)
                , count(new (std::nothorw) int(1)) // use the no throw version of new.
            {
                // Check if the pointer correctly allocated
                if (count == nullptr)
                {
                    // If we failed then delete the pointer
                    // and manually throw the exception.
                    delete data;
                    throw std::bad_alloc();
                }
            }
            // or
     .....
            explicit SP(T* data)
            // The rarely used try/catch for exceptions in argument lists.
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
}
```
### Problem 2: DRY up the Assignment
Currently the assignment operator is exception safe and conforms to the strong exception guarantee so there is no real problem here. **But** there seems to be a lot of duplicated code in the class.

Closer look at assignment
```c
namespace ThorsAnvil
{
     .....
            SP& operator=(SP const& rhs)
            {
                T*   oldData  = data;
                int* oldCount = count;

                data  = rhs.data;
                count = rhs.count;
                ++(*count);

                --(*oldCount);
                if (*oldCount == 0)
                {
                    delete oldData;
                }
            }
}
```
Two portions of this look like other code pieces of code that have already been written:

    // This looks like the SP copy constructor.
                    data  = rhs.data;
                    count = rhs.count;
                    ++(*count);

    // This looks like the SP destructor.
                    --(*oldCount);
                    if (*oldCount == 0)
                    {
                        delete oldData;
                    }
This observation is commonly referred to as the **[Copy and Swap Idiom](http://stackoverflow.com/questions/3279543/what-is-the-copy-and-swap-idiom)**. I will not go through all the details of the transformation here. But we can re-write the assignment operator as:

Copy and Swap Idiom
```c
SP& operator=(SP const& rhs)
{
    // constructor of tmp handles increment.
    SP tmp(rhs);

    std::swap(data,  tmp.data);
    std::swap(count, tmp.count);
    return *this;
}   // the destructor of tmp is executed here.
    // this handles the decrement and release of the pointer

// This is usually simplified further into
SP& operator=(SP rhs) // Note implicit copy because of pass by value.
{
    rhs.swap(*this);  // swaps moved to swap method.
    return *this;
}
```

## Fixed First Try
So given the problems described above we can update our implementation to compensate for these issues:

Fixed First Try
```c
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
                --(*count);
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
            T* get()                 const {return data;}
            explicit operator bool() const {return data;}
        };
}
```
## Summary
So in this second post we have looked SP and mentioned the two main implementation techniques commonly used. We specifically looked in detail at some common problems usually overlooked in the counted implementation of SP. In the next article I want to look at a couple of other issues common to both types of smart pointers.
