//
//  Constants.swift
//  WeTrain
//
//  Created by Bobby Ren on 10/1/15.
//  Copyright © 2015 Bobby Ren. All rights reserved.
//

import Foundation


let TESTING: Int32 = 0 // notiafications sent while training

let TRAINING_TITLES = ["Liposuction","Shred Factory","Belly Busters", "Mobi-Fit", "Sports Endurance", "The BLT","Healthy Heart","Tyrannosaurus Flex"]
let TRAINING_SUBTITLES = ["Weight Loss","Strength","Core" , "Flexibility", "Cardio" , "Butt, Legs & Tummy","Cardio","Strength and Hypertrophy"]
let TRAINING_ICONS = ["exercise_lipo", "exercise_shredFactory", "exercise_bellyBusters", "exercise_mobiFit",  "exercise_sportsEndurance", "exercise_blt","exercise_healthyHeart","exercise_tflex"]

let DESC_ICONS = ["desc_lipo", "desc_shredFactory", "desc_bellyBusters", "desc_mobiFit", "desc_sportsEndurance", "desc_blt"]

let TRAINING_DESC = ["Geared towards weight loss, the Liposuction workout will have you sizzling and chiseling the pounds away! Expect workouts involving body weight movements designed to elevate your heart rate and kick start your metabolism!",
    "A body toning workout focused on firming up muscles and giving you definition. You won't stop moving in this high-intensity circuit workout, getting a full body burn and leaving no muscle behind!",
    "Tone, tighten and ripple! The Belly Buster is a core blasting workout designed to give you six-pack abs and improve your functional stability. As an added bonus, a strong core helps reduce lower back pain and improve posture!",
    "Flexibility is important for your health and prevents future injuries. The Mobi-Fit workout is similar to a high-intensity yoga style workout. It features both static and dynamic stretching along with full range of motion exercises to improve muscle flexibility!",
    "Are you an athlete looking to improve your performance on the field? The Sports Endurance workout features interval training combined with explosive movements. This workout will improve agility, endurance, speed, and overall athletic performance! ",
    "A staff favorite! The BLT focuses on toning three core muscle groups: your butt, legs and tummy (hence the name!). Expect body weight exercises featuring isometric holds combined with light cardio to get your BLT in shape!"]


let FUN_FACTS = ["The WeTrain team reached level 19 on Black Ops 3 zombies.",
                "Co founding member Zach Hertzel can hold his breath for 3 minutes. The world record is 20 minutes and 10 seconds by Stig Seveninerson.",
                "The oldest Wetrain team member is 29, the youngest member is 20.",
                "All WeTrain team members were overweight... except Zach.",
                "Two of the WeTrain team member were diagnosed with cancer in high school.",
                "Two of the WeTrain team members can’t grow facial hair despite there best efforts.",
                "One of the WeTrain team members tried to get out of a speeding ticket by saying he was narcoleptic.",
                "Two of our bikes were stolen in center city last week, please stop...",
                "You burn more fat when your asleep than any other point in the day, even when your running!",
                "Your body releases adrenaline when you exercise on a empty stomach.",
                "Target fat loss is a myth, i.e. doing sit-ups will not burn belly fat.",
                "The world record for the most number of non-stop push ups is 10,507 by Minoru Yoshida of Japan!",
                "The world record for planking is 5 hours! This was set by a Marine.",
                "The world record for the most pull-up in 24hrs is 4,321!",
                "Andre the Giant drank 119 beers in 6 hours!"]

enum RequestState: String {
    case NoRequest = "none"
    case Searching = "requested"
    case Matched = "matched"
    case Training = "training"
    case Cancelled = "cancelled"
    case Complete = "complete"
}

enum VideoRequestState: String {
    case NoRequest = "none"
    case Searching = "requested"
    case Matched = "matched"
    case VideoRecordStarted = "RecordStarted"
    case VideoRecordProcessing = "RecordProcessing"
    case VideoUploadedStart = "videoUploadStart"
    case VideoUploaded = "videoUploaded"
    case Cancelled = "cancelled"
    case Complete = "complete"
}

enum ScheduleState: String {
    case Created            = "created"
    case Edited             = "edited"
    case Searching          = "requested"
    case GoingOn            = "goingOn"
    case Canceled           = "cancelled"
    case Expired            = "expired"
    case SelfConfirmed      = "selfConfirmed"

}

enum RatingState: String {
    case Rated = "rated"
    case MayBeLater = "maybeLater"
}

enum confimationScreentype: Int {
    case None                   = 0
    case FromMap                = 1
    case FromWorkOutReminder    = 2
    case SessonDetails          = 3

}


let PHILADELPHIA_LAT = 39.949508
let PHILADELPHIA_LON = -75.171886
let SERVICE_RANGE_METERS: Double = 8046 // 5 mile radius
let SCHEDULE_SERVICE_RANGE_METERS: Double = 32186 // 20 mile radius
let REQUEST_DISTANCE_METERS: Double = 48000 // 30 mile radius

let GOOGLE_API_APP_KEY = "AIzaSyA7aDRZVW3-ruvbeB25tzJF5WKr0FjyRac"
let STRIPE_PUBLISHABLE_KEY_DEV = "pk_test_44V2WNWqf37KXEnaJE2CM5rf"
let STRIPE_PUBLISHABLE_KEY_PROD = "pk_live_egDYTQMRk9mIkZYQPp0YtwFn"

/*
let PARSE_APP_ID_DEV = "PSgTQ91JT6JQUjmm5XmdylwCMPzckertjqul6AKL"
let PARSE_CLIENT_KEY_DEV = "EwYejFi8NGJ8XSLLlEfv4XPgSzPksGzeIO94Ljo1"
let PARSE_APP_ID_PROD = "hezlwzG8F2RaalhHOVsUrpn5xN2KNtDa8VTgd8ea"
let PARSE_CLIENT_KEY_PROD = "J0ZkdjRLVBIgaPKAAkVEvGzBQymjv2nUeaPBZkM7"*/


let PARSE_APP_ID_DEV = "PSgTQ91JT6JQUjmm5XmdylwCMPzckertjqul6AKL"
let PARSE_CLIENT_KEY_DEV = "EwYejFi8NGJ8XSLLlEfv4XPgSzPksGzeIO94Ljo1"
let PARSE_APP_ID_PROD = "hezlwzG8F2RaalhHOVsUrpn5xN2KNtDa8VTgd8ea"
let PARSE_CLIENT_KEY_PROD = "J0ZkdjRLVBIgaPKAAkVEvGzBQymjv2nUeaPBZkM7"






