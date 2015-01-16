    namespace ThorsAnvil
    {
                SP& SP::operator=(SP const& rhs)
                {
                    // Save old data
                    T*   oldData  = data;
                    int* oldCount = count;
                    
                    // now we do an exception safe transfer;
                    data  = rhs.data;
                    count = rhs.count;

                    // Update Reference Counte
                    ++(*count);
                    --(*oldCount);

                    // Delete if required
                    if (*oldCount == 0)
                    {
                        delete oldData;
                    }
                }
    }
