# juze_converter is a tool to convert JUCE applications from British to American spelling

[JUCE](https://juce.com/") is one of the only frameworks that uses British 
spelling rather than American spelling.  This tool converts both JUCE itself and
applications that use JUCE from British to American spelling.

## Usage:

`$ /path/to/juce_converter.rb <source dir>`

## Output:

The tool lists all files that have been converted and all words that have been
subtituted.

## Does it work?

Yes, both Projucer, and our [app](https://decomposer.de/sitala.html) of more than
10,000 lines of code work after conversion.  To date, we've only tested on macOS.

## Customization:

Specifically, if you notice that words that should not be translated appear in
the command line output, you can add additional entries to `blacklist.yaml`.

## More info:

We've created a page for JUZE [here](https://decomposer.de/juze.html).
