## reading in the data
filepath <- file.path("./UCI HAR Dataset")
dtSubjectTrain <- read.table(file.path(filepath,"train","subject_train.txt"))
dtSubjectTest <- read.table(file.path(filepath, "test", "subject_test.txt"))
dtYTrain <- read.table(file.path(filepath, "train", "Y_train.txt"))
dtYTest <- read.table(file.path(filepath, "test", "Y_test.txt"))
dtXTrain <- read.table(file.path(filepath,"train","X_train.txt"))
dtXTest <- read.table(file.path(filepath,"test","X_test.txt"))

## merging the data into one dt and convert is to data.table
dtSubject <- rbind(dtSubjectTrain, dtSubjectTest)
setnames(dtSubject, "V1", "subject")
dtY <- rbind(dtYTrain, dtYTest)
setnames(dtY, "V1", "activity")
dtX <- rbind(dtXTrain, dtXTest)
dt <- cbind(dtSubject, dtY,dtX)

dt <- as.data.table(dt)

## read in features

dtFeatures <- read.table(file.path(filepath, "features.txt"))
setnames(dtFeatures, names(dtFeatures), c("featureID", "description"))
head(dtFeatures)

## subset dtFeatures to include only mean and standard deviation rows

dtFeatures <- dtFeatures[grepl("mean\\(\\)|std\\(\\)", dtFeatures$description), ]

dtFeatures <- as.data.table(dtFeatures)

dtFeatures <- dtFeatures[ ,featureCode := paste0("V", dtFeatures$featureID)]

head(dtFeatures)

## Eliminate the columns in dt for which the FeatureCode does not match. 
## Hint: with=FALSE is often useful in data.table to select columns dynamically.

setkey(dt, subject, activity)

dt <- dt[, c(key(dt), dtFeatures$featureCode), with = FALSE]

## use descriptive activity names

dtActivityLabels <- fread(file.path(filepath, "activity_labels.txt"))
setnames(dtActivityLabels, names(dtActivityLabels), c("activity", "activity_name"))

dt <- merge(dt, dtActivityLabels, by = "activity", all.x = TRUE)
setkey(dt, subject, activity, activity_name)

dt <- data.table(melt(dt, key(dt), variable.name = "featureCode"))
dt <- merge(dt, dtFeatures[, .(featureID, featureCode, description)], by = "featureCode", 
            all.x = TRUE)
 
## replace the numbers for activities by characters 
## and remove the redundant columns featureCode and featureID

dt$activity <- factor(dt$activity_name)
dt <- dt[, .(subject, activity, value, description)]

## create an independent tidy data set 
## with the average of each variable for each activity and each subject

setkey(dt,subject, activity, value, description)
dtTidy <- dt[, .(average = mean(value)), by = key(dt)]
