---
layout: post
title: "So you want to learn C++ Part-6"
date: 2013-12-05 12:34:24 -0800
comments: true
categories: 
---
## Loops

Another main feature of most (again all but the most primitive) languages is the ability to repeatedly perform the same operation multiple times. This is colloquially referred to as looping constructs. A simple example is repeatedly reading a line from a file until all the lines have been read.

There are two main traditional loop types:

### Simple traditional loop
    // Repeatidly execute `<code>` while `<condition>` evaluates to true 
    while(<condition>)
    {
        <code>
    }

    // Example: copy the standard input to the standard outut.
    std::string line;
    while(std::getline(std::cin, line))
    {
        std::cout << "Line: " << line << "\n";
    }

### Loop but execute at least once.
    // Repeatidly execute `<code>` while `<condition>` evalates to tue.
    // But the code is execute before the test, therefore the code is
    // executed at lest once.
    do
    {
        <code>
    }
    while (<condition>);

    // Example: 
    do
    {
    }
    while();

If you use while loop a lot you will find that you often find the loop looks like this:

    <init loop counter>
    while(<test loop counter>)
    {
        <code>
        <increment/decrement loop counter>
    }

    // Example: Print out the numbers 0->10
    int loop=0;
    while(loop < 10)
    {
        std::cout << loop << "\n";
        ++loop;
    }

The language provides a shorthand for this type of loop construct.

    for(<init>;<condition>;<increment>)
    {
        <code>
    }

    // Example
    for(int loop = 0;loop < 10; ++loop)
    {
        std::cout << loop << "\n";
    }


