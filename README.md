# Shell script using AWK
`subt` command for subtitles formats conversion (supports *srt*/*sub*)

Converts *srt* to *sub* (and vice versa), can shift time by given number of seconds.

**Example usage:**  

Shift time in *srt* format by 2 seconds back:  
`sh subt -i srt -t -2 file.srt`  

Convert *srt* to *sub*:  
`sh subt -i srt -o sub -f 23.145 file.srt`  

Convert *sub* to *srt* AND shift time by 1.5 seconds forward:  
`sh subt -i sub -o srt -t 1,5 -f 25.0 file.sub`

**Notes:**  
- time change must be given in seconds. Must be a real number with floating point or comma
- frame rate of the video must be given when working with sub format. Must be given in seconds. Must be a real number with floating point or comma
- input and output type must be "sub" or "srt"
- input type is obligatory
- if output type is not given, format does not change
