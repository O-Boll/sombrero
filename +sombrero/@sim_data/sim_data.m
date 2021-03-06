%--------------------------------------------------------------------------
% Sombrero is a software for simulating information transfer in
% high-density crowds.
%
% Copyright (C) 2018 Olle Eriksson
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% This file is part of Sombrero.
%
% Sombrero is free software: you can redistribute it and/or modify it under
% the terms of the GNU Lesser General Public License as published by the
% Free Software Foundation, either version 3 of the License, or (at your
% option) any later version.
%
% Sombrero is distributed in the hope that it will be useful, but WITHOUT
% ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
% FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
% License for more details.
%
% You should have received a copy of the GNU Lesser General Public License
% along with Sombrero. If not, see <http://www.gnu.org/licenses/>.
%--------------------------------------------------------------------------

classdef sim_data
% The class SIM_DATA encapsulates data obtained from crowd simulations as
% well as methods for accessing this data.
%
%   A SIM_DATA object is returned when a crowd simulation is run. It
%   contains all the data collected from the simulation, as well as methods
%   for accessing this data.
    
    properties
        
        time          = [] % The time at each time step (vector).
        positions     = [] % The position of each agent at each time step.
        accelerations = [] % The acceleration of each agent at each time step.
        velocities    = [] % The velocity of each agent at each time step.
        directions    = [] % The desired move direction of each agent at each time step.
        pressure      = [] % The pressure experienced by each agent at each time step.
        adjacency     = {} % The adjacency matrix for the contact network at each time step.
        information   = {} % The information model data for each information model at each time step.
        
    end
    methods
        
        function obj = sim_data(data)
            % Constructs a sim_data object from a struct that is put together in the function run_simulation.
            if isfield(data, 'positions') && isfield(data, 'time')
                validateattributes(data.time,...
                                   {'numeric'},...
                                   {'real', 'vector'});
                data.time = data.time(:);
                s = numel(data.time);
                obj.time = data.time;
                validateattributes(data.positions,...
                                   {'numeric'},...
                                   {'real', 'size', [NaN, 2, s]});
                [n, ~, ~] = size(data.positions);
                obj.positions = data.positions;
                if isfield(data, 'velocities')
                    validateattributes(data.velocities,...
                                       {'numeric'},...
                                       {'real', 'size', [n, 2, s]});
                    obj.velocities = data.velocities;
                end
                if isfield(data, 'accelerations')
                    validateattributes(data.accelerations,...
                                       {'numeric'},...
                                       {'real', 'size', [n, 2, s]});
                    obj.accelerations = data.accelerations;
                                end
                if isfield(data, 'directions')
                    validateattributes(data.directions,...
                                       {'numeric'},...
                                       {'real', 'size', [n, 2, s]});
                    obj.directions = data.directions;
                end
                if isfield(data, 'pressure')
                    validateattributes(data.pressure,...
                                       {'numeric'},...
                                       {'real', 'size', [n, s]});
                    obj.pressure = data.pressure;
                end
                if isfield(data, 'adjacency')
                    validateattributes(data.adjacency,...
                                       {'cell'},...
                                       {'vector', 'numel', s});
                    for k = 1 : s
                        validateattributes(data.adjacency{k},...
                                           {'numeric'},...
                                           {'size', [n, n]});
                    end
                    obj.adjacency = data.adjacency;
                end
                if isfield(data, 'information')
                    validateattributes(data.information,...
                                       {'cell'},...
                                       {'size', [s, NaN]});
                    for k = 1 : numel(data.information)
                        validateattributes(data.information{k},...
                                           {'sim_info_model'},...
                                           {});
                    end
                    obj.information = data.information;
                end
            end
        end
        
        function x = get_positions(obj, t)
            % Returns the positions of the agents at time t.
            [n, ~, ~] = size(obj.positions);
            x = zeros(n, 2);
            for i = 1 : n
                % Spline interplotation is used to approximate the
                % positions at times that lie between time steps.
                x(i, :) = spline(obj.time, squeeze(obj.positions(i, :, :)), t)';
            end
        end
        
        function dist = get_distances(obj, t)
            % Returns a matrix containing the distances between all pairs of agents at time t.
            [n, ~, ~] = size(obj.positions);
            x = obj.get_positions(t);
            dist = zeros(n, n);
            for i = 1 : n
                for j = i + 1 : n
                    dist(i, j) = sqrt(sum((x(i, :) - x(j, :)).^2));
                    dist(j, i) = dist(i, j);
                end
            end
        end
        
        function a = get_accelerations(obj, t)
            % Returns the accelerations of the agents at time t.
            [n, ~, ~] = size(obj.accelerations);
            a = zeros(n, 2);
            for i = 1 : n
                % Spline interplotation is used to approximate the
                % accelerations at times that lie between time steps.
                a(i, :) = spline(obj.time, squeeze(obj.accelerations(i, :, :)), t)';
            end
        end
        
        function v = get_velocities(obj, t)
            % Returns the velocities of the agents at time t.
            [n, ~, ~] = size(obj.velocities);
            v = zeros(n, 2);
            for i = 1 : n
                % Spline interplotation is used to approximate the
                % velocities at times that lie between time steps.
                v(i, :) = spline(obj.time, squeeze(obj.velocities(i, :, :)), t)';
            end
        end
        
        function d = get_directions(obj, t)
            % Returns the desired moving directions of the agents at time t.
            [n, ~, ~] = size(obj.directions);
            d = zeros(n, 2);
            for i = 1 : n
                % Spline interplotation is used to approximate the desired
                % moving directions at times that lie between time steps.
                d(i, :) = spline(obj.time, squeeze(obj.directions(i, :, :)), t)';
            end
            d = d ./ sqrt(sum(d'.^2))';
        end
        
        function p = get_pressure(obj, t)
            % Returns the pressures experienced by the agents at time t.
            [n, ~, ~] = size(obj.directions);
            p = zeros(n, 1);
            for i = 1 : n
                % Spline interplotation is used to approximate the pressure
                % at times that lie between time steps.
                p(i) = spline(obj.time, obj.pressure(i, :), t)';
            end
        end
        
        function v = get_speed(obj, t)
            % Returns the speeds of the agents at time t.
            [n, ~, ~] = size(obj.velocities);
            v = zeros(2, n);
            for i = 1 : n
                % Spline interplotation is used to approximate the speeds
                % at times that lie between time steps.
                v(:, i) = spline(obj.time, squeeze(obj.velocities(i, :, :)), t);
            end
            v = sum(v.^2)';
        end
        
        function rect = get_extents(obj, radii, t)
        % Returns the smallest rectangle (sim_rectangle object) aligned
        % along the coordinate axes that contains all the agents.
            
            [n, ~, ~] = size(obj.positions);
            if n > 0
                x = spline(obj.time, squeeze(obj.positions(1, :, :)), t)';
                r = radii(1);
                % Coordinates of lower left and upper right corner of the
                % the smallest rectangle that contains all agents:
                % x lower left, y lower left, x upper right and y upper
                % right.
                xll = x(1) - r;
                yll = x(2) - r;
                xur = x(1) + r;
                yur = x(2) + r;
                for i = 1 : n
                    % Spline interplotation is used to approximate the
                    % positions at times that lie between time steps.
                    x = spline(obj.time, squeeze(obj.positions(i, :, :)), t)';
                    r = radii(i);
                    if x(1) - r < xll
                        xll = x(1) - r;
                    end
                    if x(2) - r < yll
                        yll = x(2) - r;
                    end
                    if x(1) + r > xur
                        xur = x(1) + r;
                    end
                    if x(2) + r > yur
                        yur = x(2) + r;
                    end
                end
            end
            rect = sim_rectangle(xll, yll, xur - xll, yur - yll);
        end
        
    end
end
            