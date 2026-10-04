================================================================================
ASHUGANJ 450 MW COMBINED CYCLE POWER PLANT (SOUTH)
Balanced steady-state load flow study - MATLAB / Simulink / Simscape Electrical

EEE 306 Power System I Laboratory - January 2026 - Group-03, Section C-1
================================================================================

This file is procedure only. It contains no results, so it cannot go out of date.
Every number lives in the generated documents named at the bottom.


--------------------------------------------------------------------------------
RUNNING IT ON A DIFFERENT COMPUTER
--------------------------------------------------------------------------------

1. COPY THE WHOLE PROJECT FOLDER.

   Any drive, any directory, any PC. Nothing needs editing afterwards - no file
   in the project stores where the project lives. Each script finds the root
   from its own location. Keep the folder structure intact; do not copy only
   the matlab/ folder.

   Do not run it from inside a ZIP. Extract it first, to somewhere writable.

2. WHAT THE COMPUTER NEEDS.

   MATLAB, with two products:
       Simulink
       Simscape Electrical  (the Specialized Power Systems part)

   Nothing else. No internet connection, no other toolbox, no downloads, no
   licence server beyond MATLAB itself. Developed and verified on R2024a.

3. OPEN MATLAB AND MAKE THIS FOLDER THE CURRENT FOLDER.

   Either use the "Browse for folder" button above the Current Folder panel, or
   type this at the >> prompt, with the quotes, because the path has spaces:

       cd 'X:\wherever\you\put it\306 Power Project'

4. CHECK THE MACHINE FIRST. This changes nothing at all:

       RUN_ME check

   It prints the MATLAB version, whether Simulink and Simscape Electrical
   resolve, what results are already on disk with their dates, and whether the
   results folder can be written to. If anything says MISSING, stop there - the
   model cannot be solved on that machine and the rest will fail confusingly.

5. RUN THE STUDY:

       RUN_ME

   Solves all four operating cases from the dataset, redraws every figure, and
   regenerates the three HTML documents. A few minutes. It writes only into
   results/ and docs/manual/ - the dataset, the source scripts and the Simulink
   models are inputs and are never overwritten by a run.

6. READ THE OUTPUT:

       docs/manual/index.html        <- open this in any web browser


--------------------------------------------------------------------------------
IF THE OTHER COMPUTER HAS NO MATLAB
--------------------------------------------------------------------------------

Copy docs/manual/ on its own. It holds all three documents and every figure, with
no reference to anything outside that folder, so it opens in a browser on any
machine - including a phone. Everything in it was generated from the solved
results; no figure and no number in it was typed by hand.


--------------------------------------------------------------------------------
THE COMMANDS
--------------------------------------------------------------------------------

    RUN_ME              solve the four cases, redraw the figures, regenerate
                        all three documents
    RUN_ME check        report the environment; change nothing
    RUN_ME open         open the Simulink diagram, ready to present
    RUN_ME solve        solve the four cases only
    RUN_ME figures      redraw the plots and the annotated diagrams only
    RUN_ME docs         regenerate the documents from results already on disk
    RUN_ME tests        run the validation suite
    RUN_ME setup        put the project folders on the MATLAB path, and stop

Inside MATLAB, once the path is set, "ashuganj" is the same command with the
same arguments. RUN_ME is a wrapper around it that fixes the path first.

If you ever see "Unrecognized function or variable", the path was not set:
run RUN_ME setup, or just use RUN_ME for everything.


--------------------------------------------------------------------------------
WHERE THINGS ARE
--------------------------------------------------------------------------------

    RUN_ME.m                          the only command you need
    docs/manual/index.html            front door to the three documents
    docs/manual/USER_MANUAL.html      how to run it, how to demonstrate it live,
                                      how to read the tool's own screen, what to
                                      do when something fails, how to move it
    docs/manual/PROJECT_UPDATE.html   what the study found, every assumption,
                                      what data is still missing, what is next
    docs/manual/LAB_REPORT.html       the same study written up in the EEE 306
                                      labsheet form: theory, worked calculations,
                                      result tables, discussion, report questions
    simulink/main/                    the diagram to present
    matlab/data/                      the parameter dataset, with the source and
                                      status of every value
    matlab/data/assumptions/          the assumptions, kept separate from the
                                      verified data on purpose
    results/                          all solved output: CSV tables, powergui
                                      reports, plots, annotated diagrams
    docs/validation/                  what is missing, what conflicts between
                                      documents, and how the model was checked

Never edit a number inside the Simulink file. The models are generated from the
dataset, so the next run overwrites it. Change matlab/data/ and rebuild -
section 8 of the user manual gives the full sequence, including the backup rule.
