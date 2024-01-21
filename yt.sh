#!/bin/env bash 
umask 0034
unalias -a 
#unset  $GROUPS
unset PATH
export PATH=$PATH:/usr/bin/:~/.local/bin:~/my\ scripts
rm -rf $imputdir 

player="/usr/bin/mpv --really-quiet -border=no"
#player="/bin/vlc"
imageviewer="tiv" #-h 40 -w 40  "

#sandbox=/bin/firejail 
#f='--noroot --private-cache  --quiet  --noroot --nonewprivs    --seccomp  '   ## firejail config for this script
sandbox_flag="$sandbox $f " 
searchlink="https://youtube.com/results?search_query="
watchlink="https://www.youtube.com/watch?v="

#####################################################################################  
case "$@" in
    --help|-h) 
echo "Usage:  yt.sh 
    
    Youtube Viewer 

    Just execute this script and Enter search terms at prompt 
    And select the number to play when the search results shown

Options: 

    --help                  Show this message and exit
    --history               Shows previous search history
    --clear                 clears search history
" 
      ;;
  --history)
if      [ -d ~/.config/youtube_bash_script ] &&  [ -f  ~/.config/youtube_bash_script/history ]  ; then 
    cat ~/.config/youtube_bash_script/history
else  
    echo " No history to show "
    fi
      ;;  
  --clear)
if      [ -f  ~/.config/youtube_bash_script/history ]  ; then 
    rm  ~/.config/youtube_bash_script/history
    fi
      ;;  

  "")

###########################     variables  ##################
color1="tput setaf 15" #white
color2='tput setaf 05' #pink
color3='tput setaf 6'  #blue 
color4='tput setaf 11' #yelow
color5='tput setaf 1'  #red
color6='tput setaf 14'  

 ##  0 disable 1 to enable 
cleaning_cache
clear
parsen=10
exit_loop_flag=1
#redo"

###################################################

########### function  #############

function parsing() 
{
    exit_loop_flag=1
    while [ $exit_loop_flag = 1 ]
    do
        y=1
        echo searching $queryname $parsen
        yt-dlp ytsearch$parsen:"$queryname" --get-id --get-title --skip-download --no-check-certificate --flat-playlist > /tmp/.ytcache
        awk '!(NR%2) {print $0}' /tmp/.ytcache > /tmp/.ytlink 
        awk '(NR%2) {print $0}' /tmp/.ytcache > /tmp/.ytname

        while [ $y  -le $parsen ]
        do
            printf  " $($color3) $y. "
            ## echo  name
            echo $($color4)  "$(cat /tmp/.ytname  |head -$y | tail -1)$(tput sgr 0)"
            ## echo link : 
            cat /tmp/.ytlink | head -$y | tail -1

            y=$( expr $y + 1 )
        done

        echo $($color3)  "Enter the number you want to watch or enter q to exit $(tput sgr 0)"
        echo  "$($color3) Enter n to search more results"$(tput sgr 0)
        read query_video_n ;
        p="$query_video_n" ;

        if [[ "$p" != q ]] && [[ "$p" != n ]] && [[ "$p" =~ ^[0-9]+$ ]]
        then
            videoid=$(cat /tmp/.ytlink | head -$p | tail -1 )
            show_title="`cat /tmp/.ytname | head -$p | tail -1`"
            mpv=1 # for conflict
            exit_loop_flag=2
        fi
        ########################
        ## exit ##
        if [ "$p" = q ] 
        then
            exit_loop_flag=0
            clearing_cache
        fi

        ######## NEW RESULTS ######
        if [ "$p" = n ] 
        then
            echo $(tput sgr 15)"Enter the number$(tput sgr 0)"
            read input3
            parsen="$input3"
        fi 
        mpv=0 # reset conflict var
    done
}

function clearing_cache()
{
    rm -rf /tmp/.ytcache
    rm -rf /tmp/.ytlink
    rm -rf /tmp/.ytname
    rm -rf $imputfile
}

function history() {
    [ ! -d  $HOME/.config/youtube_bash_script ]  && mkdir $HOME/.config/youtube_bash_script/;

    echo "$@" >> $HOME/.config/youtube_bash_script/history
}

function showvideo() { # videoid
    echo $($color1)  " Now Playing: "
    echo " "
    echo $($color4)  "$show_title$(tput sgr 0)"
    echo $($color4)  "$(echo "Link: "$watchlink"$videoid")$(tput sgr 0)"

    #####  video play ###########

    # list quality
    echo ""
    $sandbox yt-dlp -F "$watchlink$videoid"

    echo ""
    read -p "Choose quality number: " qual ;

    $sandbox  yt-dlp -f $qual -q --user-agent "$useragent"  -c  "$watchlink$videoid" -o - |   $player -
    history "$show_title: $watchlink$videoid"
}
########## end functions ###############
########## START PROGRAM ###############
queryname=1 
while [  $queryname != q  ]
do
    # startup_name
    read -p "Insert query: " queryname ;
    if [[ $queryname = *'watch'* ]]; then
        echo 'This is a video link!'
        queryname=$(echo $queryname | cut -d '&' -f 1)
        parsing
        if [ $exit_loop_flag -eq 2 ]; then 
            showvideo 
        fi
    elif [[ $queryname = *'playlist'* ]]; then
        echo 'This is a playlist link!'
        queryname=$(echo $queryname | cut -d '&' -f 1)
        yt-dlp --flat-playlist $queryname -j | jq -r .url
        # TODO : implement recursive search in playlist
    else
        parsing
        if [ $exit_loop_flag -eq 2 ]; then 
            showvideo 
        fi
    fi
done
clearing_cache
;;
esac
