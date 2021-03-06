
# *****************************************************************************
# PART 1: SETUP                    --------------------------------------------
# *****************************************************************************

#1.1 Load saved data frames
load('cleaned_trip_data.RData')
load('cleaned_station_info.RData')

#1.2 Load libraries
library(tidyverse)
library(lubridate)
library(ggplot2)
library(leaflet)
library(mapview)
library(scales)

#1.3 Color palette for plots
cyclistic_palette = c(
  "member" = "#31393C",
  "casual" = "#3a97d3"
)

# *****************************************************************************
# PART 2: DESCRIPTIVE ANALYSIS     --------------------------------------------
# *****************************************************************************

summary(all_trips_v3$minutes_ride_length)

#2.1 In general, how are members and casual customers different?
aggregate(all_trips_v3$minutes_ride_length ~ all_trips_v3$member_casual, FUN = mean)
aggregate(all_trips_v3$minutes_ride_length ~ all_trips_v3$member_casual, FUN = max)
aggregate(all_trips_v3$minutes_ride_length ~ all_trips_v3$member_casual, FUN = min)

#2.2 Compare members and casual riders by day of the week
all_trips_v3$day_of_week <- ordered(all_trips_v3$day_of_week, 
                                    levels=c("Monday", "Tuesday", "Wednesday", "Thursday","Friday", "Saturday", "Sunday"))
aggregate(all_trips_v3$minutes_ride_length ~ all_trips_v3$member_casual + all_trips_v3$day_of_week, FUN = mean)
#aggregate(all_trips_v2$ride_length, by=list(all_trips_v2$member_casual, all_trips_v2$day_of_week), FUN = mean) ## Optional, same output

#2.3 Data by customer type and date
output1 <- all_trips_v3 %>%
  group_by(date = date(started_at), member_casual) %>%
  summarise(number_of_rides = n(),
            average_duration = mean(minutes_ride_length),
            .groups = 'drop')

#2.4 Data by customer type and weekday
output2 <- all_trips_v3 %>%
  mutate(weekday = wday(started_at,label=TRUE)) %>% #Option to replace full day of week
  group_by(member_casual, weekday) %>%
  summarise(number_of_rides = n(), 
            average_duration = mean(minutes_ride_length),
            .groups = 'drop') %>%
  arrange(member_casual, weekday)

#2.5 Data by customer type and month
output3 <- all_trips_v3 %>%
  mutate(month_of_ride = month(started_at, label = TRUE)) %>%
  group_by(member_casual, month_of_ride) %>%
  summarise(number_of_rides = n(), 
            average_duration = mean(minutes_ride_length),
            .groups = 'drop') %>%
  arrange(member_casual, month_of_ride)

#2.6 Data by customer type and ride type
output4 <- all_trips_v3 %>%
  group_by(member_casual, rideable_type_2) %>%
  summarise(number_of_rides = n(), 
            average_duration = mean(minutes_ride_length),
            .groups = 'drop') %>%
  arrange(member_casual, rideable_type_2)


# *****************************************************************************
# PART 3: VISUALIZATION            --------------------------------------------
# *****************************************************************************
# Each plot is exported manually

#3.1 Number of rides by date
output1 %>%
  ggplot(aes(x = date, y = number_of_rides, color = member_casual)) +
  geom_line() +
  labs(
    title = "Plot 1: Total Rides by Date",
    color = "Customer Type",
    x = NULL,
    y = "Number of Rides") +
  theme(
    legend.position = 'bottom',
    legend.title = element_text(size=9),
    legend.text = element_text(size=8),
    panel.background = element_rect(fill = "white"),
    plot.title = element_text(size=12, hjust = 0.5, face = "bold")) +
  scale_color_manual(values = cyclistic_palette) +
  scale_y_continuous(labels = scales::comma)

#3.2 Number of rides by month
output3 %>%
  ggplot(aes(x=month_of_ride, y=number_of_rides, fill=member_casual)) +
  geom_col() +
  facet_wrap(~member_casual) +
  labs(
    title = "Plot 2: Total Rides per Month",
    fill = "Customer Type",
    x = NULL,
    y = "Number of Rides") +
  theme(
    legend.position = 'bottom',
    legend.title = element_text(size=9),
    legend.text = element_text(size=8),
    panel.background = element_rect(fill = "white"),
    plot.title = element_text(size=12, hjust = 0.5, face = "bold")) +
  scale_fill_manual(values = cyclistic_palette) +
  scale_y_continuous(labels = scales::comma)

#3.3 Average ride duration per month
output3 %>%
  ggplot(aes(x=month_of_ride, y=average_duration, fill = member_casual)) +
  geom_col() +
  facet_wrap(~member_casual) +
  labs(
    title = "Plot 3: Average Ride Duration per Month",
    fill = "Customer Type",
    x = NULL,
    y = "Average Duration (minutes)") +
  theme(
    legend.position = 'bottom',
    legend.title = element_text(size=9),
    legend.text = element_text(size=8),
    panel.background = element_rect(fill = "white"),
    plot.title = element_text(size=12, hjust = 0.5, face = "bold")) +
  scale_fill_manual(values = cyclistic_palette) +
  scale_y_continuous(labels = scales::comma)

#3.4 Number of rides by weekday
output2 %>%
  ggplot(aes(x=weekday, y=number_of_rides, fill=member_casual)) +
  geom_col(position = "dodge") +
  labs(
    title = "Plot 4: Total Rides per Weekday",
    fill = "Customer Type",
    x = NULL,
    y = "Number of Rides") +
  theme(
    legend.position = 'bottom',
    legend.title = element_text(size=9),
    legend.text = element_text(size=8),
    panel.background = element_rect(fill = "white"),
    plot.title = element_text(size=12, hjust = 0.5, face = "bold")) +
  scale_fill_manual(values = cyclistic_palette) +
  scale_y_continuous(labels = scales::comma)

#3.5 Average ride duration by weekday
output2 %>%
  ggplot(aes(x=weekday, y=average_duration, fill=member_casual)) +
  geom_col(position = "dodge") +
  labs(
    title = "Plot 5: Average Ride Duration per Weekday",
    fill = "Customer Type",
    x = NULL,
    y = "Average Duration (minutes)") +
  theme(
    legend.position = 'bottom',
    legend.title = element_text(size=9),
    legend.text = element_text(size=8),
    panel.background = element_rect(fill = "white"),
    plot.title = element_text(size=12, hjust = 0.5, face = "bold")) +
  scale_fill_manual(values = cyclistic_palette) +
  scale_y_continuous(labels = scales::comma)

#3.6 Number of rides by rideable type
output4 %>%
  ggplot(aes(x=rideable_type_2, y=number_of_rides, fill = member_casual)) +
  geom_col() +
  facet_wrap(~member_casual) +
  labs(
    title = "Plot 6: Total Rides by Rideable Type",
    fill = "Rideable Type",
    x = NULL,
    y = "Number of Rides") +
  theme(
    legend.position = 'bottom',
    legend.title = element_text(size=9),
    legend.text = element_text(size=8),
    panel.background = element_rect(fill = "white"),
    plot.title = element_text(size=12, hjust = 0.5, face = "bold")) +
  scale_fill_manual(values = cyclistic_palette) +
  scale_y_continuous(labels = scales::comma)

#3.7 Average ride duration by rideable type
output4 %>%
  ggplot(aes(x=rideable_type_2, y=average_duration, fill = member_casual)) +
  geom_col() +
  facet_wrap(~member_casual) +
  labs(
    title = "Plot 7: Average Ride Duration by Rideable Type",
    fill = "Rideable Type",
    x = NULL,
    y = "Average Duration (minutes)") +
  theme(
    legend.position = 'bottom',
    legend.title = element_text(size=9),
    legend.text = element_text(size=8),
    panel.background = element_rect(fill = "white"),
    plot.title = element_text(size=12, hjust = 0.5, face = "bold")) +
  scale_fill_manual(values = cyclistic_palette) +
  scale_y_continuous(labels = scales::comma)

#3.8 Start Station Mapping
pal <- colorFactor(
  palette = c('#d97b08', '#226996'),
  levels = c('member', 'casual')
)

station_mapping <- leaflet(start_station_info) %>%
  addTiles() %>%
  addCircleMarkers(
    ~start_lng,
    ~start_lat,
    radius = runif(100,5,15),
    color = ~pal(member_casual),
    popup = ~as.character(start_station_name)) %>%
  addLegend(
    'bottomright',
    color = c('#d97b08', '#226996'),
    labels = c('member', 'casual'),
    title = 'Customer type')

mapshot(station_mapping, 
        url = '2021_Nov_Cyclistic_Station_Map.html')
