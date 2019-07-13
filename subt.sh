#time change must be given in seconds. Must be a real number with floating point or comma.
#frame rate of the video must be given when working with sub format. Must be given in seconds. Must be a real number with floating point or comma
#input and output type must be "sub" or "srt"
#input type is obligatory
#if output type is not given, format will not change


srt_to_sub() {
	awk -v RS="" -v FS="\n" -v time_change="$time_change" -v frame_rate="$frame_rate" '
	{
		#separate line with time
		split($2,time," --> ")
		split(time[1], time1, ":")
		split(time[2], time2, ":")
		
		#replace comma with point in seconds
		sub(/,/, ".", time1[3])		
		sub(/,/, ".", time2[3])

		#count seconds
		seconds1=0	
		seconds1+=sprintf("%f", time1[1]*3600)
		seconds1+=sprintf("%f", time1[2]*60)
		seconds1+=sprintf("%f", time1[3])

		seconds2=0
                seconds2+=sprintf("%f", time2[1]*3600)
                seconds2+=sprintf("%f", time2[2]*60)
                seconds2+=sprintf("%f", time2[3])


		#add time change seconds
		seconds1+=time_change
		seconds2+=time_change

		#count frame
		frame1=sprintf("%f", seconds1*frame_rate)
		frame2=sprintf("%f", seconds2*frame_rate)
		printf("{%u}{%u}", frame1, frame2)

		#concatenate text lines with | symbol
		for (i=3; i<NF; i++) {
			printf "%s|", $i
		}
		printf("%s\n", $NF)	
	}' $file_path
}

sub_to_srt() {
	awk -v FS="}" -v time_change="$time_change" -v frame_rate="$frame_rate" '
        {
		print NR
		
		#delete { at the beginning
		sub(/{/, "", $1)
		sub(/{/, "", $2)
		
		frame1=$1
		frame2=$2

		#count seconds
		seconds1=frame1/frame_rate
		seconds2=frame2/frame_rate
		
		#change time
		seconds1+=time_change
		seconds2+=time_change		

		#seconds to hh:mm:ss
		hours1=sprintf("%u", seconds1/3600)
		remain=seconds1-hours1*3600
		minutes1=sprintf("%u", remain/60)
		sec1=remain-minutes1*60
		
		hours2=sprintf("%u", seconds2/3600)
                remain=seconds2-hours2*3600
                minutes2=sprintf("%u", remain/60)
                sec2=remain-minutes2*60


		printf("%u:%u:%.3f --> %u:%u:%.3f\n", hours1, minutes1, sec1, hours2, minutes2, sec2)

		#split text line
		split($3, lines, "|")
		for (x in lines) {
			printf("%s\n", lines[x])
		}
		printf("\n")
	}' $file_path
} 

change_time_sub() {
	awk -v FS="}" -v time_change="$time_change" -v frame_rate="$frame_rate" '
        {
                #delete { at the beginning
                sub(/{/, "", $1)
                sub(/{/, "", $2)

                frame1=$1
                frame2=$2

                #count seconds
                seconds1=frame1/frame_rate
                seconds2=frame2/frame_rate

                #change time
                seconds1+=time_change
                seconds2+=time_change

                #seconds to frames
                frame1=seconds1*frame_rate
		frame2=seconds2*frame_rate

                printf("{%u}{%u}%s\n", frame1, frame2, $3)
        }' $file_path


}

change_time_srt() {
	awk -v RS="" -v FS="\n" -v time_change="$time_change" '
        {
                #separate line with time
                split($2,time," --> ")
                split(time[1], time1, ":")
                split(time[2], time2, ":")

                #replace comma with point in seconds
                sub(/,/, ".", time1[3])         
                sub(/,/, ".", time2[3])         

                #count seconds
                seconds1=0    
                seconds1+=sprintf("%f", time1[1]*3600)
                seconds1+=sprintf("%f", time1[2]*60)
                seconds1+=sprintf("%f", time1[3])

                seconds2=0
                seconds2+=sprintf("%f", time2[1]*3600)
                seconds2+=sprintf("%f", time2[2]*60)
                seconds2+=sprintf("%f", time2[3])


                #add time change seconds
                seconds1+=time_change
                seconds2+=time_change

                #seconds to hh:mm:ss
                hours1=sprintf("%u", seconds1/3600)
                remain=seconds1-hours1*3600
                minutes1=sprintf("%u", remain/60)
                sec1=remain-minutes1*60

                hours2=sprintf("%u", seconds2/3600)
                remain=seconds2-hours2*3600
                minutes2=sprintf("%u", remain/60)
                sec2=remain-minutes2*60

                #print
		printf("%s\n", NR)
		printf("%u:%u:%.3f --> %u:%u:%.3f\n", hours1, minutes1, sec1, hours2, minutes2, sec2)
                for (i=3; i<=NF; i++) {
                        printf("%s\n", $i)
                }
                printf("\n")
         
        }' $file_path

}


type_check() { # checks if type in {sub, srt}
	[ $1 != sub -a $1 != srt ] && echo Neznamy format $1 && exit
}

number_check() { # checks if number (can be floating point)
	if [[ ! $1 =~ ^[+-]?[0-9]+[\.,]?[0-9]*$ ]]; then
		echo Argument $1 neni cislo && exit
	fi
}

while getopts ":t:i:o:f:" name; do
	case $name in
		f ) number_check $OPTARG; frame_rate=$OPTARG;;
		t ) number_check $OPTARG; time_change=$OPTARG;;
		i ) type_check $OPTARG; in_type=$OPTARG;;
		o ) type_check $OPTARG; out_type=$OPTARG;;
		\? ) echo "Neznamy prepinac $OPTARG"; exit;;
		: ) echo "Chybi hodnota prepinace $OPTARG"; exit;;
	esac
done

shift `expr $OPTIND - 1`

file_path=$1

#parameters check
[ -z $file_path ] && echo 'Poslednim parametrem musi byt jmeno souboru'
[ -z $in_type ] && echo 'Parametr -i je povinny.'
if [[ $in_type == sub || $out_type == sub ]]; then
	[ -z $frame_rate ] && echo 'Parametr -f je povinny pri praci s formatem sub.'
fi

#if floating point number written with comma, translate
[ ! -z $time_change ] && time_change=` echo $time_change | tr ',' '.' `
[ ! -z $frame_rate ] && frame_rate=` echo $frame_rate | tr ',' '.' `

if [[ $in_type == sub && $out_type == srt ]]; then
	sub_to_srt
elif [[ $in_type == srt && $out_type == sub ]]; then
	srt_to_sub
elif [ ! -z $time_change ]; then
	[ $in_type == sub ] && change_time_sub
	[ $in_type == srt ] && change_time_srt
else #no format change or time change -> only write file
	cat $file_path
fi

