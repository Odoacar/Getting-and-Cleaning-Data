README
================

Creating project folder and setting up working directory
--------------------------------------------------------

I created a folder in my Coursera directory: "./Getting\_and\_Cleaning\_Data/project", then I set that directory as working directory using setwd("./Getting\_and\_Cleaning\_Data/project"). I downloaded the files for the project and unzipped them to the project folder. The dataset unzipped to a folder called "UCI HAR Dataset". The following lists the files contained in this dataset. The argument recursive causes the function to list also the content of subfolders. The list shows all files, but only the contents of the folders "test" and "train" shall be used, except for the contents of the subfolders "Inertial Signals".

``` r
list.files("UCI HAR Dataset",recursive = TRUE)
```

    ##  [1] "activity_labels.txt"                         
    ##  [2] "features_info.txt"                           
    ##  [3] "features.txt"                                
    ##  [4] "README.txt"                                  
    ##  [5] "test/Inertial Signals/body_acc_x_test.txt"   
    ##  [6] "test/Inertial Signals/body_acc_y_test.txt"   
    ##  [7] "test/Inertial Signals/body_acc_z_test.txt"   
    ##  [8] "test/Inertial Signals/body_gyro_x_test.txt"  
    ##  [9] "test/Inertial Signals/body_gyro_y_test.txt"  
    ## [10] "test/Inertial Signals/body_gyro_z_test.txt"  
    ## [11] "test/Inertial Signals/total_acc_x_test.txt"  
    ## [12] "test/Inertial Signals/total_acc_y_test.txt"  
    ## [13] "test/Inertial Signals/total_acc_z_test.txt"  
    ## [14] "test/subject_test.txt"                       
    ## [15] "test/X_test.txt"                             
    ## [16] "test/y_test.txt"                             
    ## [17] "train/Inertial Signals/body_acc_x_train.txt" 
    ## [18] "train/Inertial Signals/body_acc_y_train.txt" 
    ## [19] "train/Inertial Signals/body_acc_z_train.txt" 
    ## [20] "train/Inertial Signals/body_gyro_x_train.txt"
    ## [21] "train/Inertial Signals/body_gyro_y_train.txt"
    ## [22] "train/Inertial Signals/body_gyro_z_train.txt"
    ## [23] "train/Inertial Signals/total_acc_x_train.txt"
    ## [24] "train/Inertial Signals/total_acc_y_train.txt"
    ## [25] "train/Inertial Signals/total_acc_z_train.txt"
    ## [26] "train/subject_train.txt"                     
    ## [27] "train/X_train.txt"                           
    ## [28] "train/y_train.txt"

Load required packages
----------------------

data.table is used. It is assumed that the package has already been downloaded and needs only be installed.

``` r
library(data.table)
```

Reading in the data
-------------------

To read in the required 6 files, I set the file path to the dataset. Then I read in the files using read.table().

``` reading
filepath <- file.path("./UCI HAR Dataset")
dtSubjectTrain <- read.table(file.path(filepath,"train","subject_train.txt"))
dtSubjectTest <- read.table(file.path(filepath, "test", "subject_test.txt"))
dtYTrain <- read.table(file.path(filepath, "train", "Y_train.txt"))
dtYTest <- read.table(file.path(filepath, "test", "Y_test.txt"))
dtXTrain <- read.table(file.path(filepath,"train","X_train.txt"))
dtXTest <- read.table(file.path(filepath,"test","X_test.txt"))
```

Merging the training and the test sets to create one data set
-------------------------------------------------------------

The merged dataset shall contain first the rows from the training files, then the rows from the test files, so first I bind the rows of the Subject test and train files as well as the Y test and train files and the X train and test files. Then I bind the columns from the resulting files. Since I will need the files to be in data.table format, I then convert dt to data.table format.

``` merging
dtSubject <- rbind(dtSubjectTrain, dtSubjectTest)
setnames(dtSubject, "V1", "subject")
dtY <- rbind(dtYTrain, dtYTest)
setnames(dtY, "V1", "activity")
dtX <- rbind(dtXTrain, dtXTest)
dt <- cbind(dtSubject, dtY,dtX)

dt <- as.data.table(dt)
```

Extract only the measurements on the mean and standard deviation for each measurement
-------------------------------------------------------------------------------------

In the created dataset there are now 561 features labelled V1 - V561. The description for these features is in the file "features.txt". We need to extract only those features including the strings "std" and "mean". The first step is to read in the features file. Then we need to subset dtFeatures to include only the rows containing mean and standard deviation measurements. I now need to convert into data.table format (I should or could have done this before).

``` extracting
dtFeatures <- read.table(file.path(filepath, "features.txt"))
setnames(dtFeatures, names(dtFeatures), c("featureID", "description"))

dtFeatures <- dtFeatures[grepl("mean\\(\\)|std\\(\\)", dtFeatures$description), ]

dtFeatures <- as.data.table(dtFeatures)

dtFeatures <- dtFeatures[ ,featureCode := paste0("V", dtFeatures$featureID)]
```

Eliminate the columns in dt for which the FeatureCode does not match. Hint: with=FALSE is often useful in data.table to select columns dynamically.

``` eliminate
setkey(dt, subject, activity)

dt <- dt[, c(key(dt), dtFeatures$featureCode), with = FALSE]
```

Use descriptive activity names to name the activities in the data set
---------------------------------------------------------------------

The activities are labelled in the file activity\_labels.txt. We will read in this file. I had thought that read.table reads in as data.table, but it reads in as data.frame. This is why I had to convert to data.table with as.data.table before. I should have used fread() instead. I am doing this from now on. Then I merge the ActivityLabels dataset with dt und melt it into a readable format.

``` use
dtActivityLabels <- fread(file.path(filepath, "activity_labels.txt"))

setnames(dtActivityLabels, names(dtActivityLabels), c("activity", "activity_name"))
dt <- merge(dt, dtActivityLabels, by = "activity", all.x = TRUE)
setkey(dt, subject, activity, activity_name)
dt <- data.table(melt(dt, key(dt), variable.name = "featureCode"))
dt <- merge(dt, dtFeatures[, .(featureID, featureCode, description)], by = "featureCode", 
            all.x = TRUE)
```

Appropriately label the dataset with descriptive variable names
---------------------------------------------------------------

Replace the numbers for activities by characters and remove the redundant columns featureCode and featureID.

``` label
dt$activity <- factor(dt$activity_name)
dt <- dt[, .(subject, activity, value, description)]
```

create an independent tidy data set
-----------------------------------

with the average of each variable for each activity and each subject

``` label

setkey(dt,subject, activity, value, description)
dtTidy <- dt[, .(average = mean(value)), by = key(dt)]
```
