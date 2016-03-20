---
layout: post
title: "Vector - Part 5: The Other Stuff"
date: 2016-03-20 22:26:43 -0700
comments: true
categories: [C++, C++-By-Example, Coding]
sharing: true
footer: true
subtitle: C++ By Example
author: Loki Astari, (C)2016,
description: C++ By Example. The Vector
---

So the C++ standard specifies a set of requirements for containers. Very few requirements are specified in terms of containers so adhering to these exactly is not required (unless you want to be considered for the standard). But they provide an in-site into what can be done with them and if you support them will allow your container to be more easily used with some features of the language and standard library. I am not going to go over all of them here (that is left as an exercise for the reader), but I will go over the ones I would expect to see in a simple implementation (the kind you would see in a university project).

For details see the [latest copy of the C++ standard](http://stackoverflow.com/a/4653479/14065).

* 23.2.1  General container requirements [container.requirements.general]
* 23.2.3  Sequence containers [sequence.reqmts]


#### Internal Types
* value&#95;type
* reference
* const&#95;reference
* iterator
* const&#95;iterator
* difference&#95;type
* size&#95;type

It is worth specifying the internal types defined here. As this allows you to abstract the implementation details of the container. This will allow you to change the implementation details without users having to change there implementation; as long as the changes still provide the same interface but the interface to reference/pointers/iterators are relatively trivial and well defined.

#### Constructors

In C++11 the `std::initializer_list<T>` was introduced. This allows a better list initialization syntax to be used with user defined types. Since this is usually defined in terms of the range based construction we should probably add both of these constructors.

* Vector(std::initializer&#95;list<T> const& list)
* Vector(I begin, I end)

#### Iterators
* begin()
* rbegin()
* begin() const
* rbegin() const
* cbegin() const
* crbegin() const
* end()
* rend()
* end() const
* cend() const
* rend() const
* crend() const

The iterators are relatively easy to write. They also allow the container to be used with the new range based for that was added in C++14. So this becomes another easy add.

#### Non-Mutating Member Functions
* size() const
* bool() const

These methods are useful to add as this allows you to provided non range checked access to the container. It is the responsibility of the container user to validate that access to elements in the container are in the correct range. This can make access to the container much more efficient as the container does not need to check every access to validate its range.

#### Member Access
* operator&#91;&#93;(&lt;index&gt;)
* operator&#91;&#93;(&lt;index&gt;) const
* at(&lt;index&gt;)
* at(&lt;index&gt;) const

We provide two methods of accesses to elements in the container. `operator[](<index>)` provides unchecked accesses. The user is supposed to validate the range is correct before use, while `at(<index>)` provides validated access to the container resulting in an exception if the index is out of range.


#### Comparitors
* operator== const
* operator!= const


#### Optional Member Functions
* front()
* back()
* front() const
* back() const
* push&#95;back(&lt;object-ref&gt;)
* push&#95;back(&lt;object-rvalue-ref&gt;)
* emplace&#95;front(&lt;args...&gt;)
* emplace&#95;back(&lt;args...&gt;)
* pop&#95;front()
* pop&#95;back()


The following members are standard easy to implement methods of `std::vector` that I would expect to see in every implementation.

# Final

```cpp Vector
#include <type_traits>
#include <memory>
#include <algorithm>
#include <stdexcept>
#include <iterator>

template<typename T>
class Vector
{
    public:
        using value_type        = T;
        using reference         = T&;
        using const_reference   = T const&;
        using pointer           = T*;
        using const_pointer     = T const*;
        using iterator          = T*;
        using const_iterator    = T const*;
        using difference_type   = std::ptrdiff_t;
        using size_type         = std::size_t;

    private:
        size_type       capacity;
        size_type       length;
        T*              buffer;

        struct Deleter
        {
            void operator()(T* buffer) const
            {
                ::operator delete(buffer);
            }
        };

    public:
        Vector(int capacity = 10)
            : capacity(capacity)
            , length(0)
            , buffer(static_cast<T*>(::operator new(sizeof(T) * capacity)))
        {}
        template<typename I>
        Vector(I begin, I end)
            : capacity(std::distance(begin, end))
            , length(0)
            , buffer(static_cast<T*>(::operator new(sizeof(T) * capacity)))
        {
            for(auto loop = begin;loop != end; ++loop)
            {
                pushBackInternal(*loop);
            }
        }
        Vector(std::initializer_list<T> const& list)
            : Vector(std::begin(list), std::end(list))
        {}
        ~Vector()
        {
            // Make sure the buffer is deleted even with exceptions
            // This will be called to release the pointer at the end
            // of scope.
            std::unique_ptr<T, Deleter>     deleter(buffer, Deleter());

            clearElements<T>();
        }
        Vector(Vector const& copy)
            : capacity(copy.length)
            , length(0)
            , buffer(static_cast<T*>(::operator new(sizeof(T) * capacity)))
        {
            try
            {
                for(int loop = 0; loop < copy.length; ++loop)
                {
                    push_back(copy.buffer[loop]);
                }
            }
            catch(...)
            {
                clearElements<T>();
                ::operator delete(buffer);

                // Make sure the exceptions continue propagating after
                // the cleanup has completed.
                throw;
            }
        }
        Vector& operator=(Vector const& copy)
        {
            copyAssign<T>(copy);
            return *this;
        }
        Vector(Vector&& move) noexcept
            : capacity(0)
            , length(0)
            , buffer(nullptr)
        {
            move.swap(*this);
        }
        Vector& operator=(Vector&& move) noexcept
        {
            move.swap(*this);
            return *this;
        }
        void swap(Vector& other) noexcept
        {
            using std::swap;
            swap(capacity,      other.capacity);
            swap(length,        other.length);
            swap(buffer,        other.buffer);
        }

        size_type           size() const                        {return length;}
        bool                empty() const                       {return length == 0;}

        reference           operator[](size_type index)         {return buffer[index];}
        const_reference     operator[](size_type index) const   {return buffer[index];}
        reference           at(size_type index)                 {validateIndex(index);return buffer[index];}
        const_reference     at(size_type index) const           {validateIndex(index);return buffer[index];}
        reference           front()                             {return buffer[0];}
        const_reference     front() const                       {return buffer[0];}
        reference           back()                              {return buffer[length - 1];}
        const_reference     back() const                        {return buffer[length - 1];}

        iterator            begin()                             {return buffer;}
        iterator            rbegin()                            {return std::reverse_iterator<iterator>(end());}
        const_iterator      begin() const                       {return buffer;}
        const_iterator      rbegin() const                      {return std::reverse_iterator<iterator>(end());}

        iterator            end()                               {return buffer + length;}
        iterator            rend()                              {return std::reverse_iterator<iterator>(begin());}
        const_iterator      end() const                         {return buffer + length;}
        const_iterator      rend() const                        {return std::reverse_iterator<iterator>(begin());}

        const_iterator      cbegin() const                      {return begin();}
        const_iterator      crbegin() const                     {return rbegin();}
        const_iterator      cend() const                        {return end();}
        const_iterator      crend() const                       {return rend();}

        bool operator!=(Vector const& rhs) const {return !(*this == rhs);}
        bool operator==(Vector const& rhs) const
        {
            return (size() == rhs.size())
                ?  std::equal(begin(), end(), rhs.begin())
                :  false;
        }

        void push_back(T const& value)
        {
            resizeIfRequire();
            pushBackInternal(value);
        }
        void push_back(T&& value)
        {
            resizeIfRequire();
            moveBackInternal(std::forward<T>(value));
        }
        template<typename... Args>
        void emplace_back(Args&&... args)
        {
            resizeIfRequire();
            constructBackInternal(std::forward<T>(args)...);
        }
        void pop_back()
        {
            --length;
            buffer[length].~T();
        }
        void reserve(size_type capacityUpperBound)
        {
            if (capacityUpperBound > capacity)
            {
                reserveCapacity(capacityUpperBound);
            }
        }
    private:
        void validateIndex(size_type index) const
        {
            if (index >= length)
            {
                throw std::out_of_range("Out of Range");
            }
        }

        void resizeIfRequire()
        {
            if (length == capacity)
            {
                size_type     newCapacity  = capacity * 1.62;
                reserveCapacity(newCapacity);
            }
        }
        void reserveCapacity(size_type newCapacity)
        {
            Vector<T>  tmpBuffer(newCapacity);

            simpleCopy<T>(tmpBuffer);

            tmpBuffer.swap(*this);
        }
        void pushBackInternal(T const& value)
        {
            new (buffer + length) T(value);
            ++length;
        }
        void moveBackInternal(T&& value)
        {
            new (buffer + length) T(std::forward<T>(value));
            ++length;
        }
        template<typename... Args>
        void constructBackInternal(Args&&... args)
        {
            new (buffer + length) T(std::forward<Args>(args)...);
            ++length;
        }

        template<typename X>
        typename std::enable_if<std::is_nothrow_move_constructible<X>::value == false>::type
        simpleCopy(Vector<T>& dst)
        {
            std::for_each(buffer, buffer + length,
                          [&dst](T const& v){dst.pushBackInternal(v);}
                         );
        }

        template<typename X>
        typename std::enable_if<std::is_nothrow_move_constructible<X>::value == true>::type
        simpleCopy(Vector<T>& dst)
        {
            std::for_each(buffer, buffer + length,
                          [&dst](T& v){dst.moveBackInternal(std::move(v));}
                         );
        }

        template<typename X>
        typename std::enable_if<std::is_trivially_destructible<X>::value == false>::type
        clearElements()
        {
            // Call the destructor on all the members in reverse order
            for(int loop = 0; loop < length; ++loop)
            {
                // Note we destroy the elements in reverse order.
                buffer[length - 1 - loop].~T();
            }
        }

        template<typename X>
        typename std::enable_if<std::is_trivially_destructible<X>::value == true>::type
        clearElements()
        {
            // Trivially destructible objects can be re-used without using the destructor.
        }

        template<typename X>
        typename std::enable_if<(std::is_nothrow_copy_constructible<X>::value
                            &&  std::is_nothrow_destructible<X>::value) == true>::type
        copyAssign(Vector<X>& copy)
        {
            if (this == &copy)
            {
                return;
            }

            if (capacity <= copy.length)
            {
                clearElements<T>();
                length = 0;
                for(int loop = 0; loop < copy.length; ++loop)
                {
                    pushBackInternal(copy[loop]);
                }
            }
            else
            {
                // Copy and Swap idiom
                Vector<T>  tmp(copy);
                tmp.swap(*this);
            }
        }

        template<typename X>
        typename std::enable_if<(std::is_nothrow_copy_constructible<X>::value
                             &&  std::is_nothrow_destructible<X>::value) == false>::type
        copyAssign(Vector<X>& copy)
        {
            // Copy and Swap idiom
            Vector<T>  tmp(copy);
            tmp.swap(*this);
        }
};
```
