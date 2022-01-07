
# *****************************************************************************
# PART 1: SETUP AND DATA COLLECTION      --------------------------------------
# *****************************************************************************

#1.1 Load libraries
library(tidyverse)
library(lubridate)
library(dplyr)
library(ggplot2)

#1.2 Upload the Ciclystic dataset as .csv files (for each month)
data_2020_12 <- read_csv("202012-divvy-tripdata.csv")
data_2021_1 <- read_csv("202101-divvy-tripdata.csv")
data_2021_2 <- read_csv("202102-divvy-tripdata.csv")
data_2021_3 <- read_csv("202103-divvy-tripdata.csv")
data_2021_4 <- read_csv("202104-divvy-tripdata.csv")
data_2021_5 <- read_csv("202105-divvy-tripdata.csv")
data_2021_6 <- read_csv("202106-divvy-tripdata.csv")
data_2021_7 <- read_csv("202107-divvy-tripdata.csv")
data_2021_8 <- read_csv("202108-divvy-tripdata.csv")
data_2021_9 <- read_csv("202109-divvy-tripdata.csv")
data_2021_10 <- read_csv("202110-divvy-tripdata.csv")
data_2021_11 <- read_csv("202111-divvy-tripdata.csv")

# *****************************************************************************
# PART 2: COMBINE DATA INTO SINGLE FILE     -----------------------------------
# *****************************************************************************

#2.1 It is important to compare column names as they have to match perfectly before appending them
colnames(data_2020_12)
colnames(data_2021_1)
colnames(data_2021_2)
colnames(data_2021_7)
colnames(data_2021_11)
# -> All column names are the same

#2.2 Append individual files into one single data frame
all_trips <- bind_rows(data_2020_12)    #Append december 2020

for (i in 1:11) {                       #Append january to november 2021 
  df_index <- paste0('data_2021_',i)
  df <- get(df_index)
  all_trips <- bind_rows(all_trips,df)
}
rm(df)

# *****************************************************************************
# PART 3: DATA CLEANING AND PREPARATION FOR ANALYSIS     ----------------------
# *****************************************************************************

#3.1 Inspect the new table created
dim(all_trips)          #Number of rows and columns
colnames(all_trips)     #Column names
head(all_trips)         #First observations
summary(all_trips)      #Statistics
str(all_trips)          #Data types
glimpse(all_trips)

#3.2 Check for misspelled strings/categories
unique(all_trips$rideable_type)
unique(all_trips$member_casual)
unique(all_trips$start_station_name)    #To drop later: DIVVY CASSETTE REPAIR MOBILE STATION

#3.3 Check for missing values (CREDITS TO GINSAPUTRA -> INSERT LINK)
missing_val <- all_trips %>%
  sapply(function(x) sum(is.na(x))) %>%
  as.data.frame() %>%
  rename(., nulls = .) %>%
  mutate(col = colnames(all_trips), .before = nulls)
rownames(missing_val) <- 1:nrow(missing_val)

missing_val %>%     #Plots missing values for each column name
  ggplot(aes(x = nulls, y= col)) +
  geom_bar(stat = "identity", fill="#3a97d3") +
  labs(
    title = "Missing Values",
    x = NULL,
    y = "Column Names") +
  theme(
    legend.position = 'bottom',
    legend.title = element_text(size=9),
    legend.text = element_text(size=8),
    panel.background = element_rect(fill = "white"),
    plot.title = element_text(size=12, hjust = 0.5, face = "bold")) +
  scale_x_continuous(labels = scales::comma)

#3.4 Creation of variables
#a. Date variables
all_trips$date <- as.Date(all_trips$started_at)
all_trips$month <- format(as.Date(all_trips$date), "%m")
all_trips$day <- format(as.Date(all_trips$date), "%d")
all_trips$year <- format(as.Date(all_trips$date), "%Y")
all_trips$day_of_week <- format(as.Date(all_trips$date), "%A")

#b. Ride Length variable
all_trips$seconds_ride_length <- difftime(all_trips$ended_at,all_trips$started_at, units = "secs")
all_trips$minutes_ride_length <- difftime(all_trips$ended_at,all_trips$started_at, units = "mins")

all_trips$seconds_ride_length <- as.numeric(all_trips$seconds_ride_length)
all_trips$minutes_ride_length <- round(as.numeric(all_trips$minutes_ride_length), digits = 2)

#c. Join electric bikes (new and old)
all_trips$rideable_type_2 <- ifelse(all_trips$rideable_type == "classic_bike", "classic_bike", 
                                ifelse((all_trips$rideable_type == "docked_bike") | (all_trips$rideable_type == "electric_bike"),"electric_bike","other"))
unique(all_trips$rideable_type_2)

#3.5 Remove "bad" data
summary(all_trips) #ride length shows negative values and also very high values (potential outliers!)

filter_stations <- c("", " ", "DIVVY CASSETTE REPAIR MOBILE STATION")

all_trips_v2 <- all_trips %>%
  filter(minutes_ride_length > 0) %>%
  filter(!(start_station_name %in% filter_stations) &
         !(end_station_name %in% filter_stations))

#3.6 Create data frame for start station mapping
start_station_info <- select(all_trips_v2, c(
  start_station_name, member_casual, start_lat, start_lng)) %>%
  group_by(start_station_name, member_casual, start_lat, start_lng) %>%
  summarize(number_of_rides = n(), .groups = "drop") %>%
  arrange(., desc(number_of_rides)) %>%
  slice(., 1:200)       #Top 200 start stations

#3.7 Drop irrelevant columns
all_trips_v3 <- select(all_trips_v2, -c(
  start_station_id, end_station_id,
  start_station_name, end_station_name,
  start_lat, start_lng, end_lat, end_lng, ride_id))

glimpse(start_station_info)
glimpse(all_trips_v3)

# *****************************************************************************
# PART 4: EXPORT SUMMARY FILE FOR ANALYSIS    ---------------------------------
# *****************************************************************************

write.csv(all_trips_v3, file = 'cleaned_trip_data.csv')
write.csv(start_station_info, file = 'cleaned_station_info.csv')
save(all_trips_v3, file = 'cleaned_trip_data.RData')
save(start_station_info, file = 'cleaned_station_info.RData')
