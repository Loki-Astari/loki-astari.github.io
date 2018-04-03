---
layout: post
title: "Socket Protocols"
date: 2016-05-29T21:13:39-07:00
comments: true
categories: [C++, Sockets, C++-By-Example, Coding]
series: Sockets
tags: Sockets
sharing: true
footer: true
subtitle: So you want to learn C++
author: Loki Astari (C)2016
description: A very cursory look at protocols and why they are needed
---

In the previous articles I have used a very simplistic protocol. In real world situations this simple protocol is not sufficient. To provide a more robust connection between client and server a communications protocol is required so that we can validate messages are sent correctly and generate appropriate responses that can also be validated.

Designing a communication protocol is a non trivial task and personally I would look for an existing protocol that matches your use case rather than trying to create protocol from scratch.

#### Example Protocols
* HTTP&#x003A; &nbsp;https://tools.ietf.org/html/rfc2616.txt
* IRC&#x003A; &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;https://tools.ietf.org/html/rfc1490.txt

Rather than go through all the different protocols I am simply going to pick the HTTP(S) protocol and use that for further discussion. HTTP(S) is relatively well known; It is simple to implement the basics; There are well known server implementations that support it; There are well known client libraries that can be used in application development.

#### Example HTTP(S) servers
* [Apache](https://httpd.apache.org/)
* [nginx](http://nginx.org/en/)
* [Node.js](https://nodejs.org/en/about/)

#### Client Side HTTP Libraries
* [LibCurl](https://curl.haxx.se/libcurl/c/)
* [Libwww](https://www.w3.org/Library/User/Using/)
* [HttpFetch](http://http-fetcher.sourceforge.net/API/index.html)


## HTTP(S)
Basically HTTP(S) defines two object. A request object is sent from the client to the server and response object is sent back as a result of a request. The only difference between the two is the start-line. Both HTTP objects can be broken down into three pieces.

1. Start-Line
2. Header-Section
3. Body

### Start-Line

For a request object this is:
<table>
<tr><td>&#8226;&nbsp;</td><td style="width:300px">Method:</td><td>HEAD/GET/PUT/POST/DELETE</td></tr>
<tr><td>&#8226;&nbsp;</td><td style="width:300px">Space:</td><td>One Space character</td></tr>
<tr><td>&#8226;&nbsp;</td><td style="width:300px">URL:</td><td>Identification of the object/service needed</td></tr>
<tr><td>&#8226;&nbsp;</td><td style="width:300px">Space:</td><td>One Space character</td></tr>
<tr><td>&#8226;&nbsp;</td><td style="width:300px">HTTP-Version:</td><td>Usually HTTP/1.1</td></tr>
<tr><td>&#8226;&nbsp;</td><td style="width:300px">CR/LF:</td><td>Literally '\r\n'</td></tr>
</table>

#### Example:
```http
GET http://google.com/maps?id=456 HTTP/1.1\r\n
```

For a response object this is:
<table>
<tr><td>&#8226;&nbsp;</td><td style="width:300px">HTTP-Version:</td><td>Usually HTTP/1.1</td></tr>
<tr><td>&#8226;&nbsp;</td><td style="width:300px">Space:</td><td>One Space character</td></tr>
<tr><td>&#8226;&nbsp;</td><td style="width:300px">Response Code:</td><td><a href="https://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html">100->599</a></td></tr>
<tr><td>&#8226;&nbsp;</td><td style="width:300px">Space:</td><td>One Space character</td></tr>
<tr><td>&#8226;&nbsp;</td><td style="width:300px">Human Readable Response:</td><td>Human readable explanation of the response code</td></tr>
<tr><td>&#8226;&nbsp;</td><td style="width:300px">CR/LF:</td><td>Literally '\r\n'</td></tr>
</table>

#### Example:
```http
HTTP/1.1 200 OK\r\n
```

### Header-Section

This is a set of key/value pairs one per line separated by a colon. Each Line is terminated by CR/LF and the end of the header section is marked by an empty line.

<table>
<tr><td>&#8226;&nbsp;</td><td style="width:300px">Key:</td><td>A text string representing the keys.</td></tr>
<tr><td>&#8226;&nbsp;</td><td style="width:300px">Colon:</td><td>A single colon (note: some implementations are lax and insert a space before the colon).</td></tr>
<tr><td>&#8226;&nbsp;</td><td style="width:300px">Space:</td><td>One Space character (note: some implementations are lax and more then one space may be present)</td></tr>
<tr><td>&#8226;&nbsp;</td><td style="width:300px">Value:</td><td>A set of characters that does not include CR or LF.</td></tr>
<tr><td>&#8226;&nbsp;</td><td style="width:300px">CR/LF:</td><td>Literally '\r\n'</td></tr>
</table>

#### Example
```http
Content-Length: 42\r\n
Content-Type: text/text\r\n
\r\n
```

### Body

The payload of the object should be in the body. Its size is defined by the headers defined in [rfc-2616 section 4.4 Message Length](https://tools.ietf.org/html/rfc2616#section-4.4).

### Required Headers

According to the rfc(s) [7230](https://tools.ietf.org/html/rfc7230), [7231](https://tools.ietf.org/html/rfc7231), [7232](https://tools.ietf.org/html/rfc7232), [7233](https://tools.ietf.org/html/rfc7233), [7234](https://tools.ietf.org/html/rfc7234) or [7235](https://tools.ietf.org/html/rfc7235) there are no header fields there are actually required header fields.

#### Request Object
But real world implementations need some headers to work efficiently, so you probably should send the following headers when making a request to a server:

* [Content-Type](https://tools.ietf.org/html/rfc7231#section-3.1.1.5):
* [Content-Length](https://tools.ietf.org/html/rfc7230#section-3.3.2):   // Or use one of the other techniques to specify length
* [Host](https://tools.ietf.org/html/rfc7230#section-5.4):

It is also polite to send the following.

* [User-Agent](https://tools.ietf.org/html/rfc7231#section-5.5.3):
* [Accept](https://tools.ietf.org/html/rfc7231#section-5.3.2):

#### Response Object
A server implementation "Must" send a `Date:` header field if it is a reasonable approximation of UTC. But that means servers may not supply the `Date:` field so you can't say it is a requirement of the standard. But you will usually see the following headers returned from a server:

* [Date](https://tools.ietf.org/html/rfc7231#section-7.1.1.2):
* [Server](https://tools.ietf.org/html/rfc7231#section-7.4.2):
* [Content-Length](https://tools.ietf.org/html/rfc7230#section-3.3.2):
* [Content-Type](https://tools.ietf.org/html/rfc7231#section-3.1.1.5):

## Implementation

Given this very basic protocol; it seems like the implementation of these requirements should be quite trivial. To be honest the implementation of creating the objects to send is relatively trivial, the hard part is reading objects from the stream in an efficiently and correctly validated manner. You can find my attempt [here](https://github.com/Loki-Astari/Examples/tree/master/Version3): It works but its 500 lines long and only covers the most basics parts of the protocol and does not do any of the hard parts (like authentication or HTTPS).

To use this protocol correctly you really need to use one of the existing libraries. Here I have re-implemented the client using libcurl.

[Client uses libcurl wrapper](https://github.com/Loki-Astari/Examples/blob/master/Version4/client.cpp)
```c
int main(int argc, char* argv[])
{
    namespace Sock = ThorsAnvil::Socket;
    if (argc != 3)
    {
        std::cerr << "Usage: client <host> <Message>\n";
        std::exit(1);
    }

    Sock::CurlGlobal    curlInit;
    Sock::CurlPost      connect(argv[1], 8080);

    connect.sendMessage("/message", argv[2]);

    std::string message;
    connect.recvMessage(message);
    std::cout << message << "\n";
}
```


[libCurl simple wrapper](https://github.com/Loki-Astari/Examples/blob/master/Version4/client.cpp)
```c
#include "Utility.h"
#include <curl/curl.h>
#include <sstream>
#include <iostream>
#include <cstdlib>

namespace ThorsAnvil
{
    namespace Socket
    {

class CurlGlobal
{
    public:
        CurlGlobal()
        {
            if (curl_global_init(CURL_GLOBAL_ALL) != 0)
            {
                throw std::runtime_error(buildErrorMessage("CurlGlobal::", __func__, ": curl_global_init: fail"));
            }
        }
        ~CurlGlobal()
        {
            curl_global_cleanup();
        }
};

extern "C" size_t curlConnectorGetData(char *ptr, size_t size, size_t nmemb, void *userdata);

enum RequestType {Get, Head, Put, Post, Delete};
class CurlConnector
{
    CURL*       curl;
    std::string host;
    int         port;
    std::string response;

    friend size_t curlConnectorGetData(char *ptr, size_t size, size_t nmemb, void *userdata);
    std::size_t getData(char *ptr, size_t size)
    {
        response.append(ptr, size);
        return size;
    }
    template<typename Param, typename... Args>
    void curlSetOptionWrapper(CURLoption option, Param parameter, Args... errorMessage)
    {
        CURLcode res;
        if ((res = curl_easy_setopt(curl, option, parameter)) != CURLE_OK)
        {
            throw std::runtime_error(buildErrorMessage(errorMessage..., curl_easy_strerror(res)));
        }
    }

    public:
        CurlConnector(std::string const& host, int port)
            : curl(curl_easy_init( ))
            , host(host)
            , port(port)
        {
            if (curl == NULL)
            {
                throw std::runtime_error(buildErrorMessage("CurlConnector::", __func__, ": curl_easy_init: fail"));
            }
        }
        ~CurlConnector()
        {
            curl_easy_cleanup(curl);
        }
        CurlConnector(CurlConnector&)               = delete;
        CurlConnector& operator=(CurlConnector&)    = delete;
        CurlConnector(CurlConnector&& rhs) noexcept
            : curl(nullptr)
        {
            rhs.swap(*this);
        }
        CurlConnector& operator=(CurlConnector&& rhs) noexcept
        {
            rhs.swap(*this);
            return *this;
        }
        void swap(CurlConnector& other) noexcept
        {
            using std::swap;
            swap(curl, other.curl);
            swap(host, other.host);
            swap(port, other.port);
            swap(response, other.response);
        }

        virtual RequestType getRequestType() const = 0;

        void sendMessage(std::string const& urlPath, std::string const& message)
        {
            std::stringstream url;
            response.clear();
            url << "http://" << host;
            if (port != 80)
            {
                url << ":" << port;
            }
            url << urlPath;

            CURLcode res;
            auto sListDeleter = [](struct curl_slist* headers){curl_slist_free_all(headers);};
            std::unique_ptr<struct curl_slist, decltype(sListDeleter)> headers(nullptr, sListDeleter);
            headers = std::unique_ptr<struct curl_slist, decltype(sListDeleter)>(curl_slist_append(headers.get(), "Content-Type: text/text"), sListDeleter);

            curlSetOptionWrapper(CURLOPT_HTTPHEADER,        headers.get(),          "CurlConnector::", __func__, ": curl_easy_setopt CURLOPT_HTTPHEADER:");
            curlSetOptionWrapper(CURLOPT_ACCEPT_ENCODING,   "*/*",                  "CurlConnector::", __func__, ": curl_easy_setopt CURLOPT_ACCEPT_ENCODING:");
            curlSetOptionWrapper(CURLOPT_USERAGENT,         "ThorsCurl-Client/0.1", "CurlConnector::", __func__, ": curl_easy_setopt CURLOPT_USERAGENT:");
            curlSetOptionWrapper(CURLOPT_URL,               url.str().c_str(),      "CurlConnector::", __func__, ": curl_easy_setopt CURLOPT_URL:");
            curlSetOptionWrapper(CURLOPT_POSTFIELDSIZE,     message.size(),         "CurlConnector::", __func__, ": curl_easy_setopt CURLOPT_POSTFIELDSIZE:");
            curlSetOptionWrapper(CURLOPT_COPYPOSTFIELDS,    message.data(),         "CurlConnector::", __func__, ": curl_easy_setopt CURLOPT_COPYPOSTFIELDS:");
            curlSetOptionWrapper(CURLOPT_WRITEFUNCTION,     curlConnectorGetData,   "CurlConnector::", __func__, ": curl_easy_setopt CURLOPT_WRITEFUNCTION:");
            curlSetOptionWrapper(CURLOPT_WRITEDATA,         this,                   "CurlConnector::", __func__, ": curl_easy_setopt CURLOPT_WRITEDATA:");

            switch(getRequestType())
            {
                case Get:       res = CURLE_OK; /* The default is GET. So do nothing.*/         break;
                case Head:      res = curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, "HEAD");    break;
                case Put:       res = curl_easy_setopt(curl, CURLOPT_PUT, 1);                   break;
                case Post:      res = curl_easy_setopt(curl, CURLOPT_POST, 1);                  break;
                case Delete:    res = curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, "DELETE");  break;
                default:
                    throw std::domain_error(buildErrorMessage("CurlConnector::", __func__, ": invalid method: ", static_cast<int>(getRequestType())));
            }
            if (res != CURLE_OK)
            {
                throw std::runtime_error(buildErrorMessage("CurlConnector::", __func__, ": curl_easy_setopt CURL_METHOD:", curl_easy_strerror(res)));
            }
            if ((res = curl_easy_perform(curl)) != CURLE_OK)
            {
                throw std::runtime_error(buildErrorMessage("CurlConnector::", __func__, ": curl_easy_perform:", curl_easy_strerror(res)));
            }
        }
        void recvMessage(std::string& message)
        {
            message = std::move(response);
        }
};

class CurlPost: public CurlConnector
{
    public:
        using CurlConnector::CurlConnector;
        virtual RequestType getRequestType() const {return Post;}

};

size_t curlConnectorGetData(char *ptr, size_t size, size_t nmemb, void *userdata)
{
    CurlConnector*  self = reinterpret_cast<CurlConnector*>(userdata);
    return self->getData(ptr, size * nmemb);
}

    }
}
```

