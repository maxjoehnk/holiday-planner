use chrono::{DateTime, NaiveDate, NaiveTime, TimeZone, Local};
use regex::Regex;
use anyhow::{Result, anyhow};

#[derive(Debug, Clone)]
pub struct ParsedTrainSegment {
    pub train_number: Option<String>,
    pub departure_station_name: String,
    pub departure_station_city: Option<String>,
    pub departure_station_country: Option<String>,
    pub departure_scheduled_platform: Option<String>,
    pub arrival_station_name: String,
    pub arrival_station_city: Option<String>,
    pub arrival_station_country: Option<String>,
    pub arrival_scheduled_platform: Option<String>,
    pub scheduled_departure_time: DateTime<Local>,
    pub scheduled_arrival_time: DateTime<Local>,
}

#[derive(Debug, Clone)]
pub struct ParsedTrainJourney {
    pub segments: Vec<ParsedTrainSegment>,
    pub journey_url: Option<String>,
}

pub fn parse_db_train_info(shared_text: &str) -> Result<ParsedTrainJourney> {
    let lines: Vec<&str> = shared_text.lines().collect();
    
    let date = extract_date(&lines)?;
    
    let journey_url = extract_journey_url(shared_text);
    
    let segments = parse_train_segments(&lines, date)?;
    
    if segments.is_empty() {
        return Err(anyhow!("No train segments found in the shared text"));
    }
    
    Ok(ParsedTrainJourney {
        segments,
        journey_url,
    })
}

fn extract_date(lines: &[&str]) -> Result<NaiveDate> {
    // Look for date pattern like "Sat 23.08.2025"
    let date_regex = Regex::new(r"\w+\s+(\d{1,2})\.(\d{1,2})\.(\d{4})")?;
    
    for line in lines.iter().take(5) { // Check first few lines
        if let Some(captures) = date_regex.captures(line) {
            let day: u32 = captures[1].parse()?;
            let month: u32 = captures[2].parse()?;
            let year: i32 = captures[3].parse()?;
            
            return NaiveDate::from_ymd_opt(year, month, day)
                .ok_or_else(|| anyhow!("Invalid date: {}.{}.{}", day, month, year));
        }
    }
    
    Err(anyhow!("No date found in the shared text"))
}

fn extract_journey_url(text: &str) -> Option<String> {
    let url_regex = Regex::new(r"https://[^\s]+").ok()?;
    url_regex.find(text).map(|m| m.as_str().to_string())
}

fn parse_train_segments(lines: &[&str], date: NaiveDate) -> Result<Vec<ParsedTrainSegment>> {
    let mut segments = Vec::new();
    let mut i = 0;
    
    while i < lines.len() {
        if let Some(segment) = parse_single_train_segment(lines, &mut i, date)? {
            segments.push(segment);
        } else {
            i += 1;
        }
    }
    
    Ok(segments)
}

fn parse_single_train_segment(lines: &[&str], index: &mut usize, date: NaiveDate) -> Result<Option<ParsedTrainSegment>> {
    let train_number_regex = Regex::new(r"^(IC|ICE|RE|RB|S)")?;
    let bus_number_regex = Regex::new(r"^(Bus)")?;
    let train_time_station_regex = Regex::new(r"^(From|To)\s+(\d{1,2}):(\d{2})\s+([^,]+)(,\s*Platform\s+(.+))?$")?;
    let bus_time_station_regex = Regex::new(r"^(From|To)\s+(\d{1,2}):(\d{2})\s+([^,]+,[^,]+)(,\s*Bus stop\s+(.+))?$")?;

    while *index < lines.len() {
        let line = lines[*index].trim();

        let regex;
        let train_number;
        if train_number_regex.captures(line).is_some() {
            train_number = line.to_string();
            regex = &train_time_station_regex;
        }else if bus_number_regex.captures(line).is_some() {
            train_number = line.to_string();
            regex = &bus_time_station_regex;
        }else {
            *index += 1;
            continue;
        }

        // Look for departure and arrival information in the following lines
        let mut departure_info = None;
        let mut arrival_info = None;

        *index += 1;

        // Skip destination line (e.g., "To Berlin Ostbahnhof")
        if *index < lines.len() && lines[*index].trim().starts_with("To ") {
            *index += 1;
        }

        // Parse From and To lines
        while *index < lines.len() && *index < lines.len() {
            let line = lines[*index].trim();

            if let Some(captures) = regex.captures(line) {
                let direction = &captures[1];
                let hour: u32 = captures[2].parse()?;
                let minute: u32 = captures[3].parse()?;
                let station_info = captures[4].trim();
                let platform = captures.get(6).map(|p| p.as_str().trim().to_string());

                let time = NaiveTime::from_hms_opt(hour, minute, 0)
                    .ok_or_else(|| anyhow!("Invalid time: {}:{}", hour, minute))?;
                let datetime = date.and_time(time);
                let local_datetime = Local.from_local_datetime(&datetime).earliest().unwrap();

                let (station_name, station_city) = parse_station_info(station_info);

                if direction == "From" {
                    departure_info = Some((station_name, station_city, platform, local_datetime));
                } else if direction == "To" {
                    arrival_info = Some((station_name, station_city, platform, local_datetime));
                }

                *index += 1;

                if departure_info.is_some() && arrival_info.is_some() {
                    break;
                }
            } else if line.is_empty() || train_number_regex.is_match(line) || bus_number_regex.is_match(line) {
                break;
            } else {
                *index += 1;
            }
        }

        if let (Some((dep_name, dep_city, dep_platform, dep_time)),
                Some((arr_name, arr_city, arr_platform, arr_time))) = (departure_info, arrival_info) {
            return Ok(Some(ParsedTrainSegment {
                train_number: Some(train_number),
                departure_station_name: dep_name,
                departure_station_city: dep_city,
                departure_station_country: None,
                departure_scheduled_platform: dep_platform,
                arrival_station_name: arr_name,
                arrival_station_city: arr_city,
                arrival_station_country: None,
                arrival_scheduled_platform: arr_platform,
                scheduled_departure_time: dep_time,
                scheduled_arrival_time: arr_time,
            }));
        }
    }
    
    Ok(None)
}

fn parse_station_info(station_info: &str) -> (String, Option<String>) {
    (station_info.to_string(), None)
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::{DateTime, Datelike, NaiveDate, NaiveTime, TimeZone, Local};

    #[test]
    fn test_parse_db_train_info() {
        let sample_text = r#"Amsterdam Centraal → Bremen Hbf
Sat 23.08.2025

IC 147
To Berlin Ostbahnhof
From 12:00 Amsterdam Centraal, Platform 8a
To 14:51 Osnabrück Hbf, Platform 11

ICE 200
To Hamburg-Harburg
From 15:23 Osnabrück Hbf, Platform 3
To 16:15 Bremen Hbf, Platform 10

View journey: https://int.bahn.de/en/buchung/start?vbid=78d16ffd-0c54-4f7f-9ea7-33403c8b3b8a"#;
        
        let result = parse_db_train_info(sample_text).unwrap();

        let date = NaiveDate::from_ymd_opt(2025, 8, 23).unwrap();
        assert_eq!(result.segments.len(), 2);
        assert!(result.journey_url.is_some());
        let first_segment = &result.segments[0];
        assert_eq!(first_segment.train_number, Some("IC 147".to_string()));
        assert_eq!(first_segment.departure_station_name, "Amsterdam Centraal");
        assert_eq!(first_segment.departure_scheduled_platform, Some("8a".to_string()));
        assert_eq!(first_segment.scheduled_departure_time, parse_date(date, 12, 0));
        assert_eq!(first_segment.arrival_station_name, "Osnabrück Hbf");
        assert_eq!(first_segment.arrival_scheduled_platform, Some("11".to_string()));
        assert_eq!(first_segment.scheduled_arrival_time, parse_date(date, 14, 51));
        let second_segment = &result.segments[1];
        assert_eq!(second_segment.train_number, Some("ICE 200".to_string()));
        assert_eq!(second_segment.departure_station_name, "Osnabrück Hbf");
        assert_eq!(second_segment.departure_scheduled_platform, Some("3".to_string()));
        assert_eq!(second_segment.scheduled_departure_time, parse_date(date, 15, 23));
        assert_eq!(second_segment.arrival_station_name, "Bremen Hbf");
        assert_eq!(second_segment.arrival_scheduled_platform, Some("10".to_string()));
        assert_eq!(second_segment.scheduled_arrival_time, parse_date(date, 16, 15));
    }

    #[test]
    fn test_parse_different_train_info() {
        let text = r#"Burgstädt → Bremen Hbf
Sun 20.07.2025

RE 6 (74181)
To Leipzig Hbf
From 14:43 Burgstädt, Platform 2
To 15:33 Leipzig Hbf, Platform 23

IC 1934
To Emden Hbf
From 16:02 Leipzig Hbf, Platform 12
To 20:09 Bremen Hbf, Platform 3

View journey: https://int.bahn.de/en/buchung/start?vbid=8679ba57-e633-4eca-a8ec-182e97bec9ae"#;

        let result = parse_db_train_info(text).unwrap();

        let date = NaiveDate::from_ymd_opt(2025, 7, 20).unwrap();
        assert_eq!(result.segments.len(), 2);
        let first_segment = &result.segments[0];
        assert_eq!(first_segment.train_number, Some("RE 6 (74181)".to_string()));
        assert_eq!(first_segment.departure_station_name, "Burgstädt");
        assert_eq!(first_segment.departure_scheduled_platform, Some("2".to_string()));
        assert_eq!(first_segment.scheduled_departure_time, parse_date(date, 14, 43));
        assert_eq!(first_segment.arrival_station_name, "Leipzig Hbf");
        assert_eq!(first_segment.arrival_scheduled_platform, Some("23".to_string()));
        assert_eq!(first_segment.scheduled_arrival_time, parse_date(date, 15, 33));
        let second_segment = &result.segments[1];
        assert_eq!(second_segment.train_number, Some("IC 1934".to_string()));
        assert_eq!(second_segment.departure_station_name, "Leipzig Hbf");
        assert_eq!(second_segment.departure_scheduled_platform, Some("12".to_string()));
        assert_eq!(second_segment.scheduled_departure_time, parse_date(date, 16, 2));
        assert_eq!(second_segment.arrival_station_name, "Bremen Hbf");
        assert_eq!(second_segment.arrival_scheduled_platform, Some("3".to_string()));
        assert_eq!(second_segment.scheduled_arrival_time, parse_date(date, 20, 9));
    }

    #[test]
    fn test_parse_bus_train_info() {
        let text = r#"Ricarda-Huch-Straße, Bremen → Burgstädt
Fri 18.07.2025

Bus 27
To Brinkum-Nord / IKEA/Marktkauf
From 15:35 Ricarda-Huch-Straße, Bremen
To 15:42 Hauptbahnhof-Nord/Messe, Bremen, Bus stop D

IC 2433
To Leipzig Hbf
From 16:08 Bremen Hbf, Platform 1
To 20:15 Leipzig Hbf, Platform 13

RE 6 (74192)
To Chemnitz Hbf
From 21:21 Leipzig Hbf, Platform 23
To 22:12 Burgstädt, Platform 2

View journey: https://int.bahn.de/en/buchung/start?vbid=b31ce3d3-b926-461e-823e-7cf92dc3e316"#;

        let result = parse_db_train_info(text).unwrap();

        let date = NaiveDate::from_ymd_opt(2025, 7, 18).unwrap();
        assert_eq!(result.segments.len(), 3);
        let first_segment = &result.segments[0];
        assert_eq!(first_segment.train_number, Some("Bus 27".to_string()));
        assert_eq!(first_segment.departure_station_name, "Ricarda-Huch-Straße, Bremen");
        assert_eq!(first_segment.departure_scheduled_platform, None);
        assert_eq!(first_segment.scheduled_departure_time, parse_date(date, 15, 35));
        assert_eq!(first_segment.arrival_station_name, "Hauptbahnhof-Nord/Messe, Bremen");
        assert_eq!(first_segment.arrival_scheduled_platform, Some("D".to_string()));
        assert_eq!(first_segment.scheduled_arrival_time, parse_date(date, 15, 42));
        let second_segment = &result.segments[1];
        assert_eq!(second_segment.train_number, Some("IC 2433".to_string()));
        assert_eq!(second_segment.departure_station_name, "Bremen Hbf");
        assert_eq!(second_segment.departure_scheduled_platform, Some("1".to_string()));
        assert_eq!(second_segment.scheduled_departure_time, parse_date(date, 16, 8));
        assert_eq!(second_segment.arrival_station_name, "Leipzig Hbf");
        assert_eq!(second_segment.arrival_scheduled_platform, Some("13".to_string()));
        assert_eq!(second_segment.scheduled_arrival_time, parse_date(date, 20, 15));
        let third_segment = &result.segments[2];
        assert_eq!(third_segment.train_number, Some("RE 6 (74192)".to_string()));
        assert_eq!(third_segment.departure_station_name, "Leipzig Hbf");
        assert_eq!(third_segment.departure_scheduled_platform, Some("23".to_string()));
        assert_eq!(third_segment.scheduled_departure_time, parse_date(date, 21, 21));
        assert_eq!(third_segment.arrival_station_name, "Burgstädt");
        assert_eq!(third_segment.arrival_scheduled_platform, Some("2".to_string()));
        assert_eq!(third_segment.scheduled_arrival_time, parse_date(date, 22, 12));
    }

    #[test]
    fn test_extract_date() {
        let lines = vec!["Amsterdam Centraal → Bremen Hbf", "Sat 23.08.2025", ""];

        let date = extract_date(&lines).unwrap();

        assert_eq!(date.day(), 23);
        assert_eq!(date.month(), 8);
        assert_eq!(date.year(), 2025);
    }

    fn parse_date(date: NaiveDate, hour: u32, minute: u32) -> DateTime<Local> {
        let time = NaiveTime::from_hms_opt(hour, minute, 0).unwrap();
        let datetime = date.and_time(time);

        Local.from_local_datetime(&datetime).earliest().unwrap()
    }
}
