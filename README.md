# Dataquiz Resources

A running version of the economic dataquiz can be found here:

http://econ.mathematik.uni-ulm.de:4501/dataquiz/

This repository contains some additional resources used to host the shiny-based dataquiz app.
The main R package can be found here https://github.com/skranz/dataquiz.

- The directory app contains the code of a sample shiny app.

- The directory quizdir contains a quizdir as needed to run the dataquiz app. Most importantly the directory quizdir/data contains the data from which we generate the OECD, Eurostat and AMECO quizes.

- The directory scrapOECD contains some code used to scrap data from OECD websites for the quiz. It will fill the directories quizdir/data/oecd and quizdir/data/oecd_descr with separate files for each websites. They are combined to the file quizdir/data/oecd.rds by running the function `combine.oecd.quiz.data` in the dataquiz package.  