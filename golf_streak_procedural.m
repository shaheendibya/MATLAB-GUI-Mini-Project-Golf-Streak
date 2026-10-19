function golf_streak_procedural()
    % GOLF STREAK: DYNAMIC REBOUND WALLS + TRAJECTORY PREVIEW

    %1. GUI Main Window Setup
    fig = figure('Name', 'Golf Streak - Fine-Tuned Wall Challenge', ...
                 'NumberTitle', 'off', 'MenuBar', 'none', 'Resize', 'off', ...
                 'Position', [100, 50, 1100, 680], 'Color', [0.04 0.05 0.08], ...
                 'WindowButtonDownFcn', @mouseDown, ...
                 'WindowButtonMotionFcn', @mouseMove, ...
                 'WindowButtonUpFcn', @mouseUp, ...
                 'CloseRequestFcn', @closeGame);

    % Main Playing Field
    ax = axes('Parent', fig, 'Position', [0.02 0.02 0.68 0.96]);
    hold(ax, 'on'); axis(ax, [0 120 0 80]); axis off;

    % 2. Control Dashboard Panel 
    pnl = uipanel('Parent', fig, 'Position', [0.71 0.02 0.27 0.96], ...
                  'Title', 'CHALLENGE DASHBOARD', 'FontSize', 11, 'FontWeight', 'bold', ...
                  'ForegroundColor', [0.2 0.9 1], 'BackgroundColor', [0.08 0.1 0.15]);

    uicontrol('Parent', pnl, 'Style', 'text', 'String', 'MISSION STATUS', ...
              'Position', [10 590 260 22], 'BackgroundColor', [0.12 0.15 0.22], ...
              'ForegroundColor', [1 0.8 0], 'FontWeight', 'bold');

    txt_stats = uicontrol('Parent', pnl, 'Style', 'text', ...
              'String', '', 'Position', [10 475 260 110], 'BackgroundColor', [0.05 0.07 0.1], ...
              'ForegroundColor', 'w', 'FontSize', 8.5, 'HorizontalAlignment', 'left');

    txt_surface = uicontrol('Parent', pnl, 'Style', 'text', 'String', 'Surface: Fairway Grass', ...
              'Position', [10 445 260 25], 'BackgroundColor', [0.1 0.4 0.2], ...
              'ForegroundColor', 'w', 'FontWeight', 'bold');

    % Club Selection
    uicontrol('Parent', pnl, 'Style', 'text', 'String', 'SELECT CLUB', ...
              'Position', [10 415 260 18], 'BackgroundColor', [0.08 0.1 0.15], ...
              'ForegroundColor', [0.2 0.9 1], 'FontWeight', 'bold', 'HorizontalAlignment', 'left');

    cmb_club = uicontrol('Parent', pnl, 'Style', 'popupmenu', ...
               'String', {'Driver (Standard Power)', 'Putter (Low Power / Precision)', 'Sand Wedge (Bunker Resistance)'}, ...
               'Position', [10 385 260 28], 'BackgroundColor', [0.15 0.18 0.25], ...
               'ForegroundColor', 'w', 'Callback', @updateClub);

    % Controls
    uicontrol('Parent', pnl, 'Style', 'text', 'String', 'AIM ANGLE (Degrees)', ...
              'Position', [10 350 260 18], 'BackgroundColor', [0.08 0.1 0.15], ...
              'ForegroundColor', 'w', 'HorizontalAlignment', 'left');

    sld_angle = uicontrol('Parent', pnl, 'Style', 'slider', 'Min', 0, 'Max', 360, 'Value', 0, ...
                'Position', [10 325 200 20], 'Callback', @sliderAimChange);

    lbl_angle = uicontrol('Parent', pnl, 'Style', 'text', 'String', '0°', ...
                'Position', [215 325 55 20], 'BackgroundColor', [0.08 0.1 0.15], 'ForegroundColor', [0.2 0.9 1]);

    uicontrol('Parent', pnl, 'Style', 'text', 'String', 'SHOT POWER (%)', ...
              'Position', [10 290 260 18], 'BackgroundColor', [0.08 0.1 0.15], ...
              'ForegroundColor', 'w', 'HorizontalAlignment', 'left');

    sld_power = uicontrol('Parent', pnl, 'Style', 'slider', 'Min', 10, 'Max', 100, 'Value', 50, ...
                'Position', [10 265 200 20], 'Callback', @sliderPowerChange);

    lbl_power = uicontrol('Parent', pnl, 'Style', 'text', 'String', '50%', ...
                'Position', [215 265 55 20], 'BackgroundColor', [0.08 0.1 0.15], 'ForegroundColor', [1 0.8 0]);

    % Action Buttons
    btn_hit = uicontrol('Parent', pnl, 'Style', 'pushbutton', 'String', 'STRIKE BALL', ...
              'Position', [10 210 260 45], 'BackgroundColor', [0.1 0.7 0.3], ...
              'ForegroundColor', 'w', 'FontSize', 12, 'FontWeight', 'bold', 'Callback', @btnHitCallback);

    btn_next = uicontrol('Parent', pnl, 'Style', 'pushbutton', 'String', 'NEXT LEVEL', ...
               'Position', [10 158 260 40], 'BackgroundColor', [0.1 0.4 0.8], ...
               'ForegroundColor', 'w', 'FontSize', 11, 'FontWeight', 'bold', 'Enable', 'off', 'Callback', @btnNextCallback);

    btn_reset = uicontrol('Parent', pnl, 'Style', 'pushbutton', 'String', 'RESTART GAME', ...
                'Position', [10 115 260 35], 'BackgroundColor', [0.8 0.2 0.2], ...
                'ForegroundColor', 'w', 'FontWeight', 'bold', 'Callback', @btnRestartCallback);

    uicontrol('Parent', pnl, 'Style', 'text', ...
              'String', sprintf('RULES:\n• CYAN borders are solid BOUNCE WALLS!\n• RED DASHED borders are OPEN HAZARDS!\n• Trajectory line predicts wall bounces!\n• Score Hole-In-One to conserve shot budget!'), ...
              'Position', [10 10 260 95], 'BackgroundColor', [0.05 0.07 0.1], ...
              'ForegroundColor', [0.7 0.8 0.9], 'FontSize', 8, 'HorizontalAlignment', 'left');

    % 3. Game State Variables
    running = true; current_level = 1; max_levels = 10;
    spare_shots = 10; level_strokes = 0;
    game_over = false; game_won = false;

    ball_x = 18; ball_y = 40; ball_vx = 0; ball_vy = 0;
    last_safe_x = 18; last_safe_y = 40; ball_radius = 1.8;
    is_ball_moving = false; ball_sunk = false;

    is_dragging = false; drag_start = [0, 0]; drag_current = [0, 0];
    max_drag_dist = 22; max_power_speed = 4.2;
    club_power_mult = 1.0; club_type = 1;

    particles = [];
    h_dynamic = hgtransform('Parent', ax);
    
    level = generateProceduralLevel(current_level);
    ball_x = level.start(1); ball_y = level.start(2);
    last_safe_x = ball_x; last_safe_y = ball_y;

    % 4. Main Game Loop 
    while running && ishandle(fig)
        if is_ball_moving && ~ball_sunk && ~game_over
            if sqrt(ball_vx^2 + ball_vy^2) > 0.1 && (ball_x ~= last_safe_x)
                if ~isOverHazard(ball_x, ball_y, level.sand) && ~isOverHazard(ball_x, ball_y, level.water) && ...
                   (ball_x >= 8 && ball_x <= 112 && ball_y >= 8 && ball_y <= 72)
                    last_safe_x = ball_x; last_safe_y = ball_y;
                end
            end

            current_friction = 0.965;
            set(txt_surface, 'String', 'Surface: Fairway Grass', 'BackgroundColor', [0.1 0.5 0.2]);

            if isOverHazard(ball_x, ball_y, level.sand)
                current_friction = ifelse(club_type == 3, 0.90, 0.80);
                set(txt_surface, 'String', 'Surface: Sand Trap!', 'BackgroundColor', [0.6 0.5 0.1]);
                spawnParticles(ball_x, ball_y, 1, [0.9 0.8 0.4]);
            end

            for i = 1:size(level.boosts, 1)
                b = level.boosts(i, :);
                if ball_x >= b(1) && ball_x <= b(1)+b(3) && ball_y >= b(2) && ball_y <= b(2)+b(4)
                    ball_vx = ball_vx + b(5) * 0.18; ball_vy = ball_vy + b(6) * 0.18;
                    spawnParticles(ball_x, ball_y, 2, [0.1 0.9 1]);
                end
            end

            ball_x = ball_x + ball_vx; ball_y = ball_y + ball_vy;
            ball_vx = ball_vx * current_friction; ball_vy = ball_vy * current_friction;

            % Wall Collision Physics
            for i = 1:size(level.walls, 1)
                w = level.walls(i, :);
                [hit, norm_x, norm_y] = checkSegmentCollision(ball_x, ball_y, ball_radius, w(1), w(2), w(3), w(4));
                if hit
                    dot_p = ball_vx * norm_x + ball_vy * norm_y;
                    if dot_p < 0
                        ball_vx = (ball_vx - 2 * dot_p * norm_x) * w(5);
                        ball_vy = (ball_vy - 2 * dot_p * norm_y) * w(5);
                        spawnParticles(ball_x, ball_y, 5, [0.2 0.9 1]);
                    end
                end
            end

            % Out of Bounds Check
            is_oob = (~level.active_left && ball_x < 8) || ...
                     (~level.active_right && ball_x > 112) || ...
                     (~level.active_bottom && ball_y < 8) || ...
                     (~level.active_top && ball_y > 72);

            if is_oob || isOverHazard(ball_x, ball_y, level.water)
                txt_msg = ifelse(is_oob, 'OUT OF BOUNDS! (-1 Point)', 'Water Hazard! (-1 Point)');
                set(txt_surface, 'String', txt_msg, 'BackgroundColor', [0.8 0.1 0.1]);
                spawnParticles(ball_x, ball_y, 25, [1 0.2 0.2]);
                ball_x = last_safe_x; ball_y = last_safe_y;
                ball_vx = 0; ball_vy = 0; is_ball_moving = false;
                level_strokes = level_strokes + 1;
                spare_shots = spare_shots - 1;
                if spare_shots < 0, game_over = true; end
            end

            % Hole Capture Check
            dist_to_hole = sqrt((ball_x - level.hole(1))^2 + (ball_y - level.hole(2))^2);
            speed = sqrt(ball_vx^2 + ball_vy^2);
            if dist_to_hole < (level.hole_radius + 0.6)
                if speed < 2.0
                    ball_sunk = true; is_ball_moving = false;
                    ball_x = level.hole(1); ball_y = level.hole(2);
                    spare_shots = spare_shots - max(0, level_strokes - level.par);
                    
                    if current_level == max_levels && spare_shots >= 0
                        game_won = true;
                    elseif spare_shots < 0
                        game_over = true;
                    else
                        set(btn_next, 'Enable', 'on');
                    end
                    spawnParticles(ball_x, ball_y, ifelse(level_strokes == 1, 80, 40), [1 0.85 0]);
                else
                    ball_vx = -ball_vx * 0.5; ball_vy = -ball_vy * 0.5;
                end
            end

            if speed < 0.04 && ~ball_sunk
                ball_vx = 0; ball_vy = 0; is_ball_moving = false;
            end
        end

        % Dashboard Status
        active_walls = {};
        if level.active_left, active_walls{end+1} = 'LEFT'; end
        if level.active_right, active_walls{end+1} = 'RIGHT'; end
        if level.active_bottom, active_walls{end+1} = 'BOTTOM'; end
        if level.active_top, active_walls{end+1} = 'TOP'; end

        set(txt_stats, 'String', sprintf('Sector: %d / %d\nPar Target: %d\nStrokes (This Level): %d\n--------------------\nBOUNCE WALLS:\n%s\n--------------------\nSPARE BUDGET: %d SHOTS', ...
            current_level, max_levels, level.par, level_strokes, strjoin(active_walls, ', '), spare_shots));

        % Particle Decay
        for i = size(particles, 1):-1:1
            particles(i, 1) = particles(i, 1) + particles(i, 3);
            particles(i, 2) = particles(i, 2) + particles(i, 4);
            particles(i, 5) = particles(i, 5) - 1;
            if particles(i, 5) <= 0, particles(i, :) = []; end
        end

        % 5. RENDER FRAME 
        delete(get(h_dynamic, 'Children'));

        rectangle('Position', [0 0 120 80], 'FaceColor', [0.04 0.06 0.1], 'EdgeColor', 'none', 'Parent', h_dynamic);
        patch(level.fairway_x, level.fairway_y, [0.12 0.45 0.2], 'EdgeColor', 'none', 'Parent', h_dynamic);

        renderBorderSegment(level.active_left, [8 8], [8 72], h_dynamic);
        renderBorderSegment(level.active_right, [112 112], [8 72], h_dynamic);
        renderBorderSegment(level.active_bottom, [8 112], [8 8], h_dynamic);
        renderBorderSegment(level.active_top, [8 112], [72 72], h_dynamic);

        for i = 1:size(level.sand, 1)
            s = level.sand(i, :);
            rectangle('Position', [s(1) s(2) s(3) s(4)], 'Curvature', [0.4 0.4], 'FaceColor', [0.82 0.72 0.42], 'EdgeColor', [0.6 0.5 0.2], 'Parent', h_dynamic);
        end
        for i = 1:size(level.water, 1)
            w = level.water(i, :);
            rectangle('Position', [w(1) w(2) w(3) w(4)], 'Curvature', [0.3 0.3], 'FaceColor', [0.1 0.45 0.85], 'FaceAlpha', 0.85, 'EdgeColor', [0.2 0.7 1], 'Parent', h_dynamic);
        end

        for i = (level.num_outer_walls + 1):size(level.walls, 1)
            w = level.walls(i, :);
            line([w(1) w(3)], [w(2) w(4)], 'Color', [0.95 0.3 0.2], 'LineWidth', 4, 'Parent', h_dynamic);
        end

        rectangle('Position', [level.hole(1)-level.hole_radius, level.hole(2)-level.hole_radius, level.hole_radius*2, level.hole_radius*2], ...
                  'Curvature', [1 1], 'FaceColor', [0.05 0.05 0.08], 'EdgeColor', [0.9 0.9 0.9], 'LineWidth', 1.5, 'Parent', h_dynamic);
        line([level.hole(1) level.hole(1)], [level.hole(2) level.hole(2)+12], 'Color', 'w', 'LineWidth', 2, 'Parent', h_dynamic);
        patch([level.hole(1) level.hole(1)+5 level.hole(1)], [level.hole(2)+12 level.hole(2)+9 level.hole(2)+6], [1 0.15 0.2], 'EdgeColor', 'none', 'Parent', h_dynamic);

        for i = 1:size(particles, 1)
            px = particles(i, 1); py = particles(i, 2); psize = (particles(i, 5) / particles(i, 6)) * 1.5;
            rectangle('Position', [px, py, psize, psize], 'Curvature', [1 1], 'FaceColor', [particles(i,7) particles(i,8) particles(i,9)], 'EdgeColor', 'none', 'Parent', h_dynamic);
        end

        if ~ball_sunk && ~game_over
            rectangle('Position', [ball_x-ball_radius, ball_y-ball_radius, ball_radius*2, ball_radius*2], ...
                      'Curvature', [1 1], 'FaceColor', [0.98 0.98 1], 'EdgeColor', [0.2 0.2 0.3], 'LineWidth', 1.2, 'Parent', h_dynamic);

            % Fine-Tuned Aiming Line with Wall Bounce Reflection Raycast
            if ~is_ball_moving
                aim_ang = deg2rad(get(sld_angle, 'Value'));
                aim_pwr = get(sld_power, 'Value') / 100;
                renderTrajectoryPreview(ball_x, ball_y, aim_ang, aim_pwr * 35, level.walls, h_dynamic);
            end
        end

        if is_dragging && ~is_ball_moving && ~ball_sunk
            dx = drag_start(1) - drag_current(1); dy = drag_start(2) - drag_current(2);
            dist = min(sqrt(dx^2 + dy^2), max_drag_dist);
            renderTrajectoryPreview(ball_x, ball_y, atan2(dy, dx), (dist / max_drag_dist) * 35, level.walls, h_dynamic);
        end

        if ball_sunk && level_strokes == 1
            text(60, 52, 'WOWW!!', 'FontSize', 44, 'FontWeight', 'bold', 'Color', [1 0.85 0], 'HorizontalAlignment', 'center', 'Parent', h_dynamic);
            text(60, 42, 'HOLE IN ONE!', 'FontSize', 16, 'FontWeight', 'bold', 'Color', [0.2 1 0.5], 'HorizontalAlignment', 'center', 'Parent', h_dynamic);
        end

        if level_strokes >= 6 && ~ball_sunk && ~game_over
            text(60, 71, 'You''re almost there!!!', 'FontSize', 20, 'FontWeight', 'bold', 'Color', [1 0.5 0.2], 'HorizontalAlignment', 'center', 'Parent', h_dynamic);
        end

        if game_won
            text(60, 45, 'VICTORY!', 'FontSize', 36, 'FontWeight', 'bold', 'Color', [0.2 1 0.4], 'HorizontalAlignment', 'center', 'Parent', h_dynamic);
        elseif game_over
            text(60, 45, 'GAME OVER', 'FontSize', 36, 'FontWeight', 'bold', 'Color', [1 0.2 0.2], 'HorizontalAlignment', 'center', 'Parent', h_dynamic);
        end

        drawnow limitrate; pause(0.02);
    end

    % 6. TRAJECTORY RAYCAST PREVIEW
    function renderTrajectoryPreview(sx, sy, angle, length_remaining, walls, parent_h)
        curr_x = sx; curr_y = sy;
        dir_x = cos(angle); dir_y = sin(angle);
        
        for bounce = 1:2 % Preview up to 1 wall bounce
            next_x = curr_x + dir_x * length_remaining;
            next_y = curr_y + dir_y * length_remaining;
            closest_dist = length_remaining; hit_wall = []; hit_pt = []; hit_norm = [];

            for i = 1:size(walls, 1)
                w = walls(i, :);
                [intersect, ix, iy, dist, nx, ny] = raySegmentIntersect(curr_x, curr_y, next_x, next_y, w(1), w(2), w(3), w(4));
                if intersect && dist < closest_dist
                    closest_dist = dist; hit_wall = w; hit_pt = [ix, iy]; hit_norm = [nx, ny];
                end
            end

            if ~isempty(hit_wall)
                line([curr_x, hit_pt(1)], [curr_y, hit_pt(2)], 'Color', [1 0.8 0.1], 'LineWidth', 2, 'LineStyle', ':', 'Parent', parent_h);
                length_remaining = length_remaining - closest_dist;
                dot_p = dir_x * hit_norm(1) + dir_y * hit_norm(2);
                dir_x = dir_x - 2 * dot_p * hit_norm(1);
                dir_y = dir_y - 2 * dot_p * hit_norm(2);
                curr_x = hit_pt(1); curr_y = hit_pt(2);
            else
                line([curr_x, next_x], [curr_y, next_y], 'Color', [1 0.8 0.1], 'LineWidth', 2, 'LineStyle', ':', 'Parent', parent_h);
                break;
            end
        end
    end

    function [hit, ix, iy, dist, nx, ny] = raySegmentIntersect(p1x, p1y, p2x, p2y, q1x, q1y, q2x, q2y)
        hit = false; ix = 0; iy = 0; dist = Inf; nx = 0; ny = 0;
        rx = p2x - p1x; ry = p2y - p1y; sx = q2x - q1x; sy = q2y - q1y;
        denom = rx * sy - ry * sx;
        if abs(denom) < 1e-5, return; end
        
        t = ((q1x - p1x) * sy - (q1y - p1y) * sx) / denom;
        u = ((q1x - p1x) * ry - (q1y - p1y) * rx) / denom;

        if t >= 0 && t <= 1 && u >= 0 && u <= 1
            hit = true; ix = p1x + t * rx; iy = p1y + t * ry;
            dist = sqrt((ix - p1x)^2 + (iy - p1y)^2);
            len_s = sqrt(sx*sx + sy*sy); nx = -sy / len_s; ny = sx / len_s;
        end
    end

    % 7. PROCEDURAL GENERATOR WITH SPAWN CLEARANCE 
    function lvl_data = generateProceduralLevel(lvl)
        lvl_data.name = sprintf('SECTOR %d', lvl);
        lvl_data.par = 3 + floor((lvl - 1) / 3);
        lvl_data.hole_radius = max(1.8, 3.6 - (lvl * 0.15));
        
        lvl_data.fairway_x = [8 112 112 8]; lvl_data.fairway_y = [8 8 72 72];
        lvl_data.start = [18, 35 + randi(10)];
        lvl_data.hole = [95 + randi(10), 18 + randi(44)];

        num_walls = randi([1, 3]); active_indices = randperm(4, num_walls);
        lvl_data.active_left   = ismember(1, active_indices);
        lvl_data.active_right  = ismember(2, active_indices);
        lvl_data.active_bottom = ismember(3, active_indices);
        lvl_data.active_top    = ismember(4, active_indices);

        lvl_data.walls = [];
        if lvl_data.active_left,   lvl_data.walls = [lvl_data.walls;   8,  8,   8, 72, 0.88]; end
        if lvl_data.active_right,  lvl_data.walls = [lvl_data.walls; 112,  8, 112, 72, 0.88]; end
        if lvl_data.active_bottom, lvl_data.walls = [lvl_data.walls;   8,  8, 112,  8, 0.88]; end
        if lvl_data.active_top,    lvl_data.walls = [lvl_data.walls;   8, 72, 112, 72, 0.88]; end

        lvl_data.num_outer_walls = size(lvl_data.walls, 1);

        % Clearance Guaranteed Obstacles
        for k = 1:min(4, floor(lvl / 2) + 1)
            wx = 35 + (k * 14) + randi(4); wy1 = randi([12, 25]); wy2 = wy1 + 20 + randi(12);
            lvl_data.walls = [lvl_data.walls; wx, wy1, wx, wy2, 0.85];
        end

        lvl_data.sand = [];
        for k = 1:min(4, floor(lvl / 2) + 1)
            sx = 25 + randi(60); sy = 12 + randi(40);
            if sqrt((sx - lvl_data.start(1))^2 + (sy - lvl_data.start(2))^2) > 15
                lvl_data.sand = [lvl_data.sand; sx, sy, 12, 10];
            end
        end

        lvl_data.water = [];
        for k = 1:max(0, min(3, floor(lvl / 2)))
            wx = 35 + randi(50); wy = 15 + randi(30);
            if sqrt((wx - lvl_data.hole(1))^2 + (wy - lvl_data.hole(2))^2) > 18
                lvl_data.water = [lvl_data.water; wx, wy, 12, 10];
            end
        end
        lvl_data.boosts = [];
    end

    % Render Helper & Callbacks
    function renderBorderSegment(is_solid, x_data, y_data, parent_h)
        line(x_data, y_data, 'Color', ifelse(is_solid, [0.2 0.9 1], [1 0.2 0.2]), ...
             'LineWidth', ifelse(is_solid, 5, 2.5), 'LineStyle', ifelse(is_solid, '-', '--'), 'Parent', parent_h);
    end

    function val = ifelse(cond, a, b), if cond, val = a; else, val = b; end, end

    function is_inside = isOverHazard(x, y, hazard_matrix)
        is_inside = false;
        for k = 1:size(hazard_matrix, 1)
            hz = hazard_matrix(k, :);
            if x >= hz(1) && x <= hz(1)+hz(3) && y >= hz(2) && y <= hz(2)+hz(4), is_inside = true; return; end
        end
    end

    function [hit, nx, ny] = checkSegmentCollision(px, py, r, x1, y1, x2, y2)
        hit = false; nx = 0; ny = 0; dx = x2 - x1; dy = y2 - y1; len_sq = dx*dx + dy*dy;
        t = max(0, min(1, ((px - x1)*dx + (py - y1)*dy) / len_sq));
        closest_x = x1 + t * dx; closest_y = y1 + t * dy;
        dist_x = px - closest_x; dist_y = py - closest_y; dist = sqrt(dist_x^2 + dist_y^2);
        if dist < r && dist > 0, hit = true; nx = dist_x / dist; ny = dist_y / dist; end
    end

    function spawnParticles(x, y, count, color_vec)
        for p = 1:count
            particles = [particles; x, y, (rand()-0.5)*2.2, (rand()-0.5)*2.2, 12+randi(12), 12+randi(12), color_vec(1), color_vec(2), color_vec(3)];
        end
    end

    function updateClub(~, ~)
        club_type = get(cmb_club, 'Value');
        club_power_mult = ifelse(club_type == 1, 1.0, ifelse(club_type == 2, 0.55, 0.8));
    end

    function sliderAimChange(~, ~), set(lbl_angle, 'String', sprintf('%d°', round(get(sld_angle, 'Value')))); end
    function sliderPowerChange(~, ~), set(lbl_power, 'String', sprintf('%d%%', round(get(sld_power, 'Value')))); end

    function btnHitCallback(~, ~)
        if is_ball_moving || ball_sunk || game_over || game_won, return; end
        ang = deg2rad(get(sld_angle, 'Value'));
        pwr = (get(sld_power, 'Value') / 100) * max_power_speed * club_power_mult;
        ball_vx = cos(ang) * pwr; ball_vy = sin(ang) * pwr;
        is_ball_moving = true; level_strokes = level_strokes + 1;
    end

    function btnNextCallback(~, ~)
        if ball_sunk && ~game_over && current_level < max_levels
            current_level = current_level + 1;
            level = generateProceduralLevel(current_level);
            ball_x = level.start(1); ball_y = level.start(2);
            last_safe_x = ball_x; last_safe_y = ball_y; ball_vx = 0; ball_vy = 0;
            level_strokes = 0; ball_sunk = false; set(btn_next, 'Enable', 'off');
        end
    end

    function btnRestartCallback(~, ~)
        current_level = 1; spare_shots = 10; level_strokes = 0;
        game_over = false; game_won = false; ball_sunk = false; is_ball_moving = false;
        level = generateProceduralLevel(current_level);
        ball_x = level.start(1); ball_y = level.start(2);
        last_safe_x = ball_x; last_safe_y = ball_y; ball_vx = 0; ball_vy = 0;
        set(btn_next, 'Enable', 'off');
    end

    function mouseDown(~, ~)
        if is_ball_moving || ball_sunk || game_over || game_won, return; end
        pt = get(ax, 'CurrentPoint'); mx = pt(1,1); my = pt(1,2);
        if sqrt((mx - ball_x)^2 + (my - ball_y)^2) < (ball_radius + 6)
            is_dragging = true; drag_start = [ball_x, ball_y]; drag_current = [mx, my];
        end
    end

    function mouseMove(~, ~)
        if is_dragging, pt = get(ax, 'CurrentPoint'); drag_current = [pt(1,1), pt(1,2)]; end
    end

    function mouseUp(~, ~)
        if is_dragging
            is_dragging = false; dx = drag_start(1) - drag_current(1); dy = drag_start(2) - drag_current(2);
            dist = min(sqrt(dx^2 + dy^2), max_drag_dist);
            if dist > 1.0
                angle = atan2(dy, dx); shot_speed = (dist / max_drag_dist) * max_power_speed * club_power_mult;
                ball_vx = cos(angle) * shot_speed; ball_vy = sin(angle) * shot_speed;
                is_ball_moving = true; level_strokes = level_strokes + 1;
            end
        end
    end

    function closeGame(~, ~), running = false; if ishandle(fig), delete(fig); end; end
end