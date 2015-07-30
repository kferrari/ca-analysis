classdef Animal < AnimalGroup
    %AnimalGroup Summary of this class goes here
    %   Detailed explanation goes here
    
    % ================================================================== %
    
    properties
        
        % basic info on this animal
        animalName
        scoresheetPath
        scoresheetData
        
        % data reference
        sessionData
        sessionImg
        
    end
    
    % ================================================================== %
    
    methods
        
        function AnimalObj = Animal(varargin)
            
            % Parse arguments
            [experimentDirIn, treatment, animalNameIn, ...
                scoresheetPathIn] = ...
                utils.parse_opt_args({'', '', '', {}}, varargin);
            
            % Call AnimalGroup (i.e. parent class) constructor
            AnimalObj = AnimalObj@AnimalGroup(experimentDirIn, treatment);
             
            % Work out the current recursion depth
            if utils.is_deeper_than('Animal.Animal')
                return;
            end
            
            % Check if input is a single animal or a group
            if ~iscell(scoresheetPathIn)
                AnimalObj.scoresheetPath = scoresheetPathIn;
                return
            end
            
            % Treat group as individual animals
            nAnimals = numel(scoresheetPathIn);
            for iAnimal = nAnimals:-1:1
                if ~isempty(animalNameIn{iAnimal})
                    AnimalObj(iAnimal).scoresheetPath = ...
                        scoresheetPathIn{iAnimal};
                    
                    AnimalObj(iAnimal).animalName = ...
                        animalNameIn{iAnimal};                    
                end
            end
            
        end
        
        % -------------------------------------------------------------- %
        
        function preprocess(self)
            
            if ~isscalar(self)
                arrayfun(@preprocess, self, 'UniformOutput', false);
                return
            end

            % Read scoresheet
            [~, ~, data] = xlsread(self.scoresheetPath);
            
            % Convert into a matlab table
            dataTable = cell2table(data(2:end,1:23));
            dataTable.Properties.VariableNames = data(1,1:23);
            self.scoresheetData = dataTable;
            
            generate_sessions(self)
            
        end
            
            % -------------------------------------------------------------- %
        
        function process(self)
            
            if ~isscalar(self)
                arrayfun(@process, self, 'UniformOutput', false);
                return
            end

            self.sessionImg.process()
            
        end
        
        % -------------------------------------------------------------- %
        
        output_data(self, varargin)
        
        % -------------------------------------------------------------- %
        
        function set.scoresheetData(self, val)
            
            % Check for cell array
            if ~istable(val)
                error('Scoresheet is no cell array')
            end
            
            % Set the property
            self.scoresheetData = val;
            
        end
        
    end
    
    % ================================================================== %
    
    methods (Access=protected)
                
        function generate_sessions(self)
            
            sessionDates = unique(self.scoresheetData.Date);
            nSessions = numel(sessionDates);
            
            for iSession = nSessions:-1:1
                
                currDate = sessionDates(iSession);
                currDateIdx = self.scoresheetData{:,'Date'} == currDate;
                self.sessionData{iSession} = self.scoresheetData(...
                    currDateIdx, :);
                
            end
            
            % Create ImagingSession from scoresheet    
            self.sessionImg = ImagingSession(self.experimentDir, ...
                self.sessionData);
            
        end
        
    end
    
    % ================================================================== %
    
    methods (Static, Hidden)
        
    end
    
    % ================================================================== %
    
end

