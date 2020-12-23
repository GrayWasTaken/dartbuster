# Dartbuster
#### Written by Gray
### URL Fuzzing / brute forcing tool, written in dart.
[license](https://github.com/dart-lang/stagehand/blob/master/LICENSE).

## Description
Easy to use async directory brute forcing tool with advanced capabilities. Dartbuster is a cross platform tool written in dart with significant performance enhancements that really make it an effective choice over pre-existing tools.

## Features
- Real time scan progress and information
- 10 built in wordlists
- 4 built in extension lists
- Built in user agents
- Rotates user agent per request (optional)
- Supports custom wordlists, extensions, and user agents
- Multithreaded and option to specify threadcount
- Specify Delay
- Supports output files
- Option to hide or show 404 responses
- Specify custom cookies
- Automatically skips common fuzzing traps such as endless redirects and optionally prints to screen
- Pre and post scan report
- Fully cross platform
- Asynchronous by nature so multiple requests will occur concurrently on a single thread.

## Usage
*** The help screen has all the information you'd need, but here are some hopefully useful examples: ***
Prints help screen
`$ dartbuster -h`
Starts fuzzing the "example.com" website, with 50 threads using wordlist apache-user-enum-1.0.txt
`$ dartbuster scan -u https://example.com -T 50 -w apache-user-enum-1.0.txt`
Starts fuzzing the "example.com" website, with the extensions .pdf, .html, .css
`$ dartbuster scan -u https://example.com -e .pdf,.html,.css`
Prints built in extension and word lists.
`$ dartbuster list`
Prints built in useragents.
`$ dartbuster useragents`



#### Todo List:
- Add recursion for directories.
- Add exclusion flags.
- Possibly add timeout.
- Possibly stop get requests where the fetched content exceeds a certain size, ie: if webserver starts an endless file stream.
- Implement isolates 2.