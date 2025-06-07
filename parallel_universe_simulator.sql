-- 1. Users Table
CREATE TABLE users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100),
    birth_year INT,
    base_location VARCHAR(100),
    personality_type VARCHAR(10), -- e.g., INTJ, ENFP
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Universes Table (each user's alternate reality)
CREATE TABLE universes (
    universe_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    universe_name VARCHAR(100),
    description TEXT,
    divergence_point DATE, -- when the universe split from reality
    universe_rating INT CHECK (universe_rating BETWEEN 1 AND 10),
    created_on DATE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- 3. Life Choices Table
CREATE TABLE life_choices (
    choice_id INT PRIMARY KEY AUTO_INCREMENT,
    universe_id INT,
    decision_area VARCHAR(50), -- e.g., career, relationship, education
    decision_text TEXT,
    impact_level ENUM('Low', 'Medium', 'High'),
    emotional_effect TEXT,
    made_on DATE,
    FOREIGN KEY (universe_id) REFERENCES universes(universe_id) ON DELETE CASCADE
);

-- 4. Events Table (consequences of decisions)
CREATE TABLE events (
    event_id INT PRIMARY KEY AUTO_INCREMENT,
    universe_id INT,
    event_title VARCHAR(100),
    description TEXT,
    occurred_on DATE,
    happiness_impact INT, -- -10 to +10 scale
    wealth_impact INT,    -- -10 to +10 scale
    career_impact INT,    -- -10 to +10 scale
    social_impact INT,    -- -10 to +10 scale
    health_impact INT,    -- -10 to +10 scale
    FOREIGN KEY (universe_id) REFERENCES universes(universe_id) ON DELETE CASCADE
);

-- 5. Relationships Table
CREATE TABLE relationships (
    relationship_id INT PRIMARY KEY AUTO_INCREMENT,
    universe_id INT,
    partner_name VARCHAR(100),
    relationship_type ENUM('Friendship', 'Romantic', 'Family', 'Rivalry', 'Mentorship'),
    bond_strength INT, -- 1 to 100
    started_on DATE,
    ended_on DATE,
    notes TEXT,
    FOREIGN KEY (universe_id) REFERENCES universes(universe_id) ON DELETE CASCADE
);

-- 6. Universe Logs Table (events + reflections)
CREATE TABLE universe_logs (
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    universe_id INT,
    log_entry TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (universe_id) REFERENCES universes(universe_id) ON DELETE CASCADE
);

-- 7. Achievements Table
CREATE TABLE achievements (
    achievement_id INT PRIMARY KEY AUTO_INCREMENT,
    universe_id INT,
    title VARCHAR(100),
    description TEXT,
    achieved_on DATE,
    FOREIGN KEY (universe_id) REFERENCES universes(universe_id) ON DELETE CASCADE
);

-- 8. View: Universe Summary
CREATE VIEW universe_summary AS
SELECT 
    un.universe_id,
    un.universe_name,
    COUNT(DISTINCT lc.choice_id) AS total_choices,
    COUNT(DISTINCT e.event_id) AS total_events,
    COUNT(DISTINCT r.relationship_id) AS total_relationships,
    AVG(e.happiness_impact) AS avg_happiness,
    AVG(e.wealth_impact) AS avg_wealth,
    AVG(e.career_impact) AS avg_career,
    AVG(e.social_impact) AS avg_social,
    AVG(e.health_impact) AS avg_health
FROM universes un
LEFT JOIN life_choices lc ON un.universe_id = lc.universe_id
LEFT JOIN events e ON un.universe_id = e.universe_id
LEFT JOIN relationships r ON un.universe_id = r.universe_id
GROUP BY un.universe_id;

-- 9. Trigger: Prevent more than 10 High Impact Decisions
DELIMITER $$
CREATE TRIGGER limit_high_impact_choices
BEFORE INSERT ON life_choices
FOR EACH ROW
BEGIN
    DECLARE high_count INT;
    SELECT COUNT(*) INTO high_count FROM life_choices
    WHERE universe_id = NEW.universe_id AND impact_level = 'High';

    IF NEW.impact_level = 'High' AND high_count >= 10 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Limit of 10 High-Impact decisions reached for this universe.';
    END IF;
END$$
DELIMITER ;

-- 10. Stored Procedure: Get Universe Timeline
DELIMITER $$
CREATE PROCEDURE get_universe_timeline(IN input_universe_id INT)
BEGIN
    SELECT 'Decision' AS type, decision_text AS description, made_on AS date
    FROM life_choices
    WHERE universe_id = input_universe_id

    UNION

    SELECT 'Event' AS type, event_title AS description, occurred_on AS date
    FROM events
    WHERE universe_id = input_universe_id

    UNION

    SELECT 'Log' AS type, log_entry AS description, created_at AS date
    FROM universe_logs
    WHERE universe_id = input_universe_id

    ORDER BY date;
END$$
DELIMITER ;
