-- =====================================================
-- Game Simulation Example (Tic-tac-toe)
-- =====================================================

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS game_moves CASCADE;
DROP TABLE IF EXISTS game_states CASCADE;

-- Create tables
CREATE TABLE game_states (
    state_id INT PRIMARY KEY,
    board_state VARCHAR(9),  -- 9 characters representing 3x3 board
    current_player CHAR(1),  -- 'X' or 'O'
    game_status VARCHAR(20)  -- 'ongoing', 'won', 'draw'
);

CREATE TABLE game_moves (
    move_id INT PRIMARY KEY,
    state_id INT,
    position INT,  -- 0-8 representing board positions
    player CHAR(1),
    resulting_state_id INT,
    FOREIGN KEY (state_id) REFERENCES game_states(state_id),
    FOREIGN KEY (resulting_state_id) REFERENCES game_states(state_id)
);

-- Insert sample game states and moves
INSERT INTO game_states VALUES
(1, '         ', 'X', 'ongoing'),  -- Empty board
(2, 'X        ', 'O', 'ongoing'),  -- X in top-left
(3, 'XO       ', 'X', 'ongoing'),  -- X top-left, O top-center
(4, 'XOX      ', 'O', 'ongoing'),  -- X top-left, O top-center, X top-right
(5, 'XOX O    ', 'X', 'ongoing'),  -- X top-left, O top-center, X top-right, O center
(6, 'XOX OX   ', 'O', 'ongoing'),  -- X top-left, O top-center, X top-right, O center, X bottom-left
(7, 'XOX OXO  ', 'X', 'ongoing'),  -- X top-left, O top-center, X top-right, O center, X bottom-left, O bottom-center
(8, 'XOX OXO X', 'O', 'won');      -- X wins with diagonal

INSERT INTO game_moves VALUES
(1, 1, 0, 'X', 2),  -- X plays in position 0
(2, 2, 1, 'O', 3),  -- O plays in position 1
(3, 3, 2, 'X', 4),  -- X plays in position 2
(4, 4, 4, 'O', 5),  -- O plays in position 4
(5, 5, 6, 'X', 6),  -- X plays in position 6
(6, 6, 7, 'O', 7),  -- O plays in position 7
(7, 7, 8, 'X', 8);  -- X plays in position 8 (wins)

-- Simulate game progression and find winning paths
WITH RECURSIVE game_simulation AS (
    -- Base case: starting state
    SELECT 
        state_id,
        board_state,
        current_player,
        game_status,
        0 as move_number,
        ARRAY[state_id] as state_path,
        ARRAY[board_state]::VARCHAR[] as board_path
    FROM game_states
    WHERE state_id = 1  -- Start with empty board
    
    UNION ALL
    
    -- Recursive case: follow possible moves
    SELECT 
        gs.state_id,
        gs.board_state,
        gs.current_player,
        gs.game_status,
        gsim.move_number + 1,
        gsim.state_path || gs.state_id,
        gsim.board_path || gs.board_state
    FROM game_states gs
    INNER JOIN game_moves gm ON gs.state_id = gm.resulting_state_id
    INNER JOIN game_simulation gsim ON gm.state_id = gsim.state_id
    WHERE gsim.game_status = 'ongoing'
    AND gsim.move_number < 9  -- Maximum 9 moves in tic-tac-toe
)
SELECT 
    move_number,
    current_player,
    board_state,
    game_status,
    board_path
FROM game_simulation
ORDER BY move_number, state_id;

-- Clean up
DROP TABLE IF EXISTS game_moves CASCADE;
DROP TABLE IF EXISTS game_states CASCADE; 