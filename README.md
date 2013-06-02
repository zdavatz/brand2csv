# brand2csv

brand2csv using swissreg.ch to get addresses.

## Usage
```
brand2csv 01.01.2013 "b*"
brand2csv 1.10.2005-31.10.2005
```
## Help
```
~> brand2csv --help
/usr/local/bin/brand2csv ver.0.1.9
Usage:
 brand2csv timespan
    Find all brands registered in switzerland during the given timespan.
     The following examples valid timespan periods:
       brand2csv 01.01.2013 "b*" #will search for all brand starting with "b"
       brand2csv 1.10.2005-31.10.2005 #this will work as well from version 0.1.9
    The results are stored in the file <date_selected>.csv.
    The trademark name is either a real brand name or a link to an image.
```
