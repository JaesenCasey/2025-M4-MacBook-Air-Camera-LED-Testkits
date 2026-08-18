# 2025-M4-MacBook-Air-Camera-LED-Testkits
An Unserious Test Kit for the 2025 M4 MacBook Air LED Camera Indicator. Supposedly applicable to later M series models as well, Instruction Programmed.

Began after a youtube short called attention to the quality engineering of the MacOS LED Camera Indicator


NOTICE(S)
-----------------------------------------------------------
Documentation practices used in this project file should not be taken at their word:

All files obtained from the internet should be inspected before execution. It is not valuable to blindly trust program files, nor execute bash files without proper inspection

AFTER EXECUTION THESE PROGRAMS WILL CAPTURE IMAGES USING THE DEVICE'S CAMERA:
 - the programs provided in this repository are in fact, aimed at capturing images using the devices front facing camera. 
   After executing any of the binaries compiled from the .swift files listed in this repository, images will be captured and written to whatever directory the program was executed from
 - the images captured by this program are never transmitted to any source, and this program does not involve any means of telemetry. 
   Theoretically you could run the program without any internet connection. However, you should not take my word for it, and should instead in any cases like this inspect the files via your own means, antivirus software, agent inspection, before taking the risk.
-----------------------------------------------------------

Project Documentation

I am not overly republe on this matter, but the source as well as anthropic models suggest that the hardware is organized in such a manner that the front camera can not physically be powered without power also being provided to the subsequent LED indicator, as they share a direct curcuit fork.

The present findings of the test seem to agree with this, though still draws attention, as proposed by another commenter, as to what would happen if the camera was powered on in such a timeframe that the led was not easily visible to the operating user. 

This repository measures directed at this framework, assuming the premise of mutual inherency to be true. 

It's current findings do not extend below the 30ms floor of camera on time, but all current runs suggest that the visibility of the LED is necessitated by any activation of the camera, currently suggesting further that there is some sort of hardware enforcement of a minimum LED up time. 

Worthwhile notes are as follows:
- every run in which the camera has been activated has also coincided aptly to the LEDs activation:
	- the led always start timely to the exectuion of camera access, findings are not exact, but have not drawn any attention as of yet to indicate delay between camera activation and led startup
- it is not yet clear whether the proposed minimum LED uptime is actually enforced, be it at a hardware level, or a software level. It is not by any means confirmed, though the documented perceptions of the LED (my own visual framing) seems to suggest that below the 500 ms threshold they all run for the same set amount of time (seems like about 500 ms)
	- tests are currently aimed at isolation with the goal of driving out this relation - camera off-time to led off-time, and measuring whether the garunteed time does in fact exist

- the nature of this test of course provides only evidence at the software lair, as this is not a manual inspection of the hardware

finally, this test is not positing applicability to other generations of the macbook model, nor to the pro models of the macbook, though it does allude to the source posting's statement that this is applicable to generations proceeding the model being tested (2025 15" M4 MacBook Air). 


File descriptions:
camera_test.swift - earlier version of camera test, don't recall exactly what its limitations were, shows however that the led activates according to called camera activation.
	 -run_cam_test.sh - shell script to execute alongside camera_test.swift, though the execution command within should be modified according to the object file output by compiling camera_test
	 -run_binary_cam_test.sh - currently the camera test prompt that is worth while, instead of linearly testing ms timeframes, decreases them exponentially. Was developed after the initial bash script was yielding results that did not seem they would noticable very. 
	 - run_camera_finality.sh - may have also been for this .swift file, I think this may have corrected the previous was absence of the jpgs or the actual image capture described below
	 - worth noting, at one point this swift files was abandoned because the images were never produced even with sufficent time to do so. That may have been remedied within the file at this point; memory recalls that it may have been remedied to the point of producing blank jpg's, or all black images
	- I believe .sh files for this swift binary are written to use "testcam" as the name of the binary output files, though it only requires a one line change within the bash files to modify the working binary name

test_camera_bid.swift - later generation. created after previous file brought to attention some intervals that did not produce jpg at first, but then after some time consecutively running the program did begin to do so (led was present in all cases, not suspicious in that way). Only real indication was that the camera startup process did not fully deinitialize, there was not discrepency noted regarding the actual camera capturing and the status of the led light
	- I dont believe this needed a bash file, run parameters desccribed at ./[executable name]

led_minimum_test.swift - current test endpoint, aimed at finding the tail between the ending of camera access and the ending of the led activation. I believe this also does not require a bash file to run


