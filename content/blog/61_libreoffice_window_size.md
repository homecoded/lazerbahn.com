% TITLE (PRODUCTIVITY) How to stop LibreOffice windows from shrinking to a very small line on Linux
% DESCRIPTION When I drag LibreOffice windows from full-size view to another monitor, they frequently collapse to a small line and become almost invisible. I wrote a small script that makes sure they always remain clickable. Here it is:
% DATE 17.10.2024

[<< Back to Overview](../blog.html)

# How to stop LibreOffice windows from shrinking to a very small line on Linux

#DATE#

When I move a LibreOffice windows (especially Calc) from full-width on one screen to another the window resizes to
a vertical dark line. The dark line is almost invisible on my dark background. This is very annoying. 
Why do LibreOffice windows collapse to such a small size anyway? 
Currently, I'm using Version: 6.4.7.2 of LibreOffice and I've been struggling with this for years.

I'm not the only one with this problem, apparently:

- [https://askubuntu.com/questions/1275213/libreofficecalc-window-is-shrunk-to-a-line-and-is-unclickable](https://askubuntu.com/questions/1275213/libreofficecalc-window-is-shrunk-to-a-line-and-is-unclickable)
- [https://forums.freebsd.org/threads/libreoffice-window-being-really-small-when-started.88163/](https://forums.freebsd.org/threads/libreoffice-window-being-really-small-when-started.88163/)

Well, I'm solving the problem with two small scripts that get started on when I begin to work:

    // file: fix-windows.sh
    #/bin/bash
    
    MIN_WIDTH=150
    
    readarray -t LibreOfficeWindows <<< $(xdotool search --onlyvisible --name LibreOffice)
    
    for i in "${LibreOfficeWindows[@]}"
    do
        readarray -t WindowGeom < <(xdotool getwindowgeometry $i)
        WindowSize=${WindowGeom[2]}
        WindowSize=$(echo $WindowSize | cut -d ' ' -f2 )
        Width=$(echo $WindowSize | cut -d 'x' -f1 )
        Height=$(echo $WindowSize | cut -d 'x' -f2 )
        IsUpdateRequired=false
        if (( $Width < $MIN_WIDTH )) ; then
            Width=$MIN_WIDTH
            IsUpdateRequired=true
        fi
        if (( $Height < $MIN_WIDTH )) ; then
            Height=$MIN_WIDTH 
            IsUpdateRequired=true
        fi
    
        if [ "$IsUpdateRequired" = true ] ; then
            #echo "Fixing window $i"
            xdotool windowsize $i $Width $Height
        fi 
    done

This goes through all LibreOffice windows and resizes them to at least 150 pixel.

Now, the other script I mentioned turns the previous script into a poor man's service task:

    // file: fix-windows-job.sh
    #/bin/bash
    echo "Running fix windows job"
    cd "$(dirname "$0")"
    
    while true
    do
        (fix-windows.sh)
        sleep 2
    done

It checks for undersized windows every 2 seconds. That is not too often but quick enough to be useful.

You can add the `fix-windows.sh` to the crontab but this will only run once a minute. Som this might not be the
best choice for you. However, you can add it using the `@reboot` directive:

    // crontab -e
    @reboot ~/fix-windows-job.sh > /dev/null 2>&1   

This should start the script on every boot automatically.

Personally, I simply added `fix-windows-job.sh` to a startup script that I run manually whenever I begin to work.

Happy coding,
Manuel
