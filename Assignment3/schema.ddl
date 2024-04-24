-- Could not:
-- At least one author on each paper must be a reviewer.
-- Reviewers cannot review their own submissions, the submissions of anyone
-- else with whom they are co-authors, or the submissions of anyone else
-- from their organization.
-- A submission can only be accepted if at least one reviewer recommends
-- 'accept'.
-- A submission must receive at least three reviews before it can have a
-- decision.
-- Previously-accepted submissions cannot be submitted again later.
-- Accepted submissions must be scheduled for a presentation.
-- Paper session chairs must be attending the conference, must not be an
-- author of any papers at that session, and they must not have anything
-- else scheduled at the same time.
-- No author can have two presentations at the same time, except authors
-- who have one paper and poster at the same time and they are not the sole
-- author for either.
-- Students pay a lower registration fee than other attendees.
-- At least one author on every accepted submission must be registered for
-- the conference.
-- Every workshop must have at least one facilitator.
-- Conferences must have at least one and at most two chairs.
-- Conference chairs must have been on the conference committee for at least
-- twice before becoming chair, unless the conference is too new.

-- Did not:
-- Any registration fee must be nonnegative. I did not enforce this since I
-- expect that anyone who uses this schema would not think that negative
-- fees are realistic.

-- Extra constraints:
-- Every email address must be unique.
-- A paper or poster must not be submitted to the same conference more than
-- once in a year.
-- For every submission, a reviewer can only review it once.
-- A submission where all of its reviewers recommend 'accept' must be
-- accepted.
-- A poster or paper can only be presented once.
-- All poster sessions in a conference must start at different times.
-- All paper sessions in a conference must start at different times.
-- Every conference attendee can only register for that conference once.
-- Anyone registering for a workshop must also be registered for
-- the respective conference.

-- Assumptions:
-- Conference names are unique.
-- A conference only happens once in a year.
-- Each conference occurrence in a year have separate conference committees.
-- The order of the authors on a poster is meaningful.
-- One of the authors for a paper or poster submits it to a conference.
-- Workshop facilitators can be anyone (e.g., presenters, non-attendees).

DROP SCHEMA IF EXISTS A3Conference CASCADE;
CREATE SCHEMA A3Conference;
SET SEARCH_PATH TO A3Conference;

-- A person involved with some submission or conference in any capacity
CREATE TABLE IF NOT EXISTS Person (
    id INT PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    organization_name TEXT NOT NULL
);

-- A paper or poster, which can have any number of authors
CREATE TABLE IF NOT EXISTS Research (
    id INT PRIMARY KEY,
    name TEXT NOT NULL,
    type TEXT CHECK (type in ('paper', 'poster'))
);

-- An author contributed to this research and they are listed as
-- the n-th author, where n is represented by 'n_order'
CREATE TABLE IF NOT EXISTS ResearchAuthor (
    research_id INT NOT NULL,
    author_id INT NOT NULL,
    n_order INT NOT NULL,
    PRIMARY KEY (research_id, author_id),
    UNIQUE (research_id, n_order),
    FOREIGN KEY (research_id) REFERENCES Research(id),
    FOREIGN KEY (author_id) REFERENCES Person(id)
);

-- A conference in a certain year and place
CREATE TABLE IF NOT EXISTS Conference (
    id INT PRIMARY KEY,
    name TEXT NOT NULL,
    year INT NOT NULL,
    location TEXT NOT NULL,
    UNIQUE (name, year)
);

-- A committee for a conference occurrence
CREATE TABLE IF NOT EXISTS ConferenceCommittee (
    conference_id INT NOT NULL,
    committee_member_id INT NOT NULL,
    is_chair BOOLEAN NOT NULL,
    PRIMARY KEY (conference_id, committee_member_id),
    FOREIGN KEY (conference_id) REFERENCES Conference(id),
    FOREIGN KEY (committee_member_id) REFERENCES Person(id)
);

-- A registration made by an attendee for an instance of a conference
CREATE TABLE IF NOT EXISTS ConferenceRegistration (
    id INT PRIMARY KEY,
    attendee_id INT NOT NULL,
    conference_id INT NOT NULL,
    fee FLOAT NOT NULL,
    is_student BOOLEAN NOT NULL,
    UNIQUE (attendee_id, conference_id),
    FOREIGN KEY (attendee_id) REFERENCES Person(id),
    FOREIGN KEY (conference_id) REFERENCES Conference(id)
);

-- A paper or poster submission made by one of the authors to an instance
-- of a conference
CREATE TABLE IF NOT EXISTS Submission (
    id INT PRIMARY KEY,
    conference_id INT NOT NULL,
    research_id INT NOT NULL,
    submitting_author_id INT NOT NULL,
    decision TEXT NOT NULL CHECK (decision in ('accept', 'reject')),
    UNIQUE (conference_id, research_id),
    FOREIGN KEY (conference_id) REFERENCES Conference(id),
    FOREIGN KEY (research_id) REFERENCES Research(id),
    FOREIGN KEY (research_id, submitting_author_id) 
        REFERENCES ResearchAuthor(research_id, author_id)
);

-- A review of a submission
CREATE TABLE IF NOT EXISTS Review (
    id INT PRIMARY KEY,
    submission_id INT NOT NULL,
    reviewer_id INT NOT NULL,
    reviewer_decision TEXT NOT NULL 
        CHECK (reviewer_decision in ('accept', 'reject')),
    UNIQUE (submission_id, reviewer_id),
    FOREIGN KEY (submission_id) REFERENCES Submission(id),
    FOREIGN KEY (reviewer_id) REFERENCES Person(id)
);

-- A poster session in a conference
CREATE TABLE IF NOT EXISTS PosterSession (
    id INT PRIMARY KEY,
    conference_id INT NOT NULL,
    start_time TIMESTAMP NOT NULL,
    UNIQUE (conference_id, start_time),
    FOREIGN KEY (conference_id) REFERENCES Conference(id)
);

-- A presentation at a poster session
CREATE TABLE IF NOT EXISTS PosterPresentation (
    poster_id INT PRIMARY KEY,
    poster_session_id INT NOT NULL,
    FOREIGN KEY (poster_session_id) REFERENCES PosterSession(id),
    FOREIGN KEY (poster_id) REFERENCES Submission(id)
);

-- A paper session in a conference
CREATE TABLE IF NOT EXISTS PaperSession (
    id INT PRIMARY KEY,
    conference_id INT NOT NULL,
    start_time TIMESTAMP NOT NULL,
    session_chair INT NOT NULL,
    UNIQUE (conference_id, start_time),
    FOREIGN KEY (conference_id) REFERENCES Conference(id),
    FOREIGN KEY (session_chair) REFERENCES Person(id)
);

-- A presentation at a paper session with a unique time
CREATE TABLE IF NOT EXISTS PaperPresentation (
    paper_id INT PRIMARY KEY,
    paper_session_id INT NOT NULL,
    presentation_time TIME NOT NULL,
    UNIQUE (paper_session_id, presentation_time),
    FOREIGN KEY (paper_session_id) REFERENCES PaperSession(id),
    FOREIGN KEY (paper_id) REFERENCES Submission(id)
);

-- A workshop in a conference
CREATE TABLE IF NOT EXISTS Workshop (
    id INT PRIMARY KEY,
    name TEXT NOT NULL,
    conference_id INT NOT NULL,
    FOREIGN KEY (conference_id) REFERENCES Conference(id)
);

-- A facilitator of a workshop
CREATE TABLE IF NOT EXISTS WorkshopFacilitator (
    workshop_id INT NOT NULL,
    facilitator_id INT NOT NULL,
    PRIMARY KEY (workshop_id, facilitator_id),
    FOREIGN KEY (workshop_id) REFERENCES Workshop(id),
    FOREIGN KEY (facilitator_id) REFERENCES Person(id)
);

-- A registration made by an attendee for a workshop
CREATE TABLE IF NOT EXISTS WorkshopRegistration (
    registration_id INT NOT NULL,
    workshop_id INT NOT NULL,
    fee FLOAT NOT NULL,
    PRIMARY KEY (registration_id, workshop_id),
    FOREIGN KEY (registration_id) REFERENCES ConferenceRegistration(id),
    FOREIGN KEY (workshop_id) REFERENCES Workshop(id)
);