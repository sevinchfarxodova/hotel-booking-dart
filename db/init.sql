CREATE TABLE IF NOT EXISTS rooms (
    id VARCHAR(16) PRIMARY KEY,
    type VARCHAR(64) NOT NULL,
    capacity INT NOT NULL,
    price_per_night INT NOT NULL
);

CREATE TABLE IF NOT EXISTS reservations (
    id VARCHAR(64) PRIMARY KEY,
    room_id VARCHAR(16) NOT NULL REFERENCES rooms(id),
    guest_name VARCHAR(128) NOT NULL,
    guest_email VARCHAR(128) NOT NULL,
    check_in DATE NOT NULL,
    check_out DATE NOT NULL,
    status VARCHAR(32) NOT NULL
);

INSERT INTO rooms (id, type, capacity, price_per_night) VALUES
    ('R7', 'Standard Double', 2, 120),
    ('R8', 'Deluxe Suite', 4, 220)
ON CONFLICT (id) DO NOTHING;
