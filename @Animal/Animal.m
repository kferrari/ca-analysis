classdef Animal < AnimalGroup
    %AnimalGroup Summary of this class goes here
    %   Detailed explanation goes here
    
    % ================================================================== %
    
    properties
        
        % info on processing state
        state
        
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
        
        function preprocess(self, varargin)
            
            if ~isscalar(self)
                arrayfun(@(x) preprocess(x, varargin{:}), self, 'UniformOutput', false);
                return
            end
            
            % Parse arguments
            [refImg] = utils.parse_opt_args({[]}, varargin);
            
            % Read scoresheet
            [~, ~, data] = xlsread(self.scoresheetPath, '', '', 'basic');
            
            % Convert into a matlab table
            dataTable = cell2table(data(2:end,1:23));
            dataTable.Properties.VariableNames = data(1,1:23);
            self.scoresheetData = dataTable;
            
            generate_sessions(self, refImg)
            
            self.state = 'preprocessed';
            
        end
            
        % -------------------------------------------------------------- %
        
        function process(self, varargin)
            
            if ~isscalar(self)
                arrayfun(@(x) process(x, varargin{:}), self);
                return
            end

            % Parse arguments
            [nBaseSessions, useParallel] = ...
                utils.parse_opt_args({1, true}, varargin);
            
            % Call Processing of ImgGroup
            self.sessionImg.process(nBaseSessions, useParallel)
            
            % TODO: Add some verification here
            self.state = 'processed';
            
        end
        
        % -------------------------------------------------------------- %
        
        function dataTable = output_data(self, varargin)
           dataTable = table(); 
           for iSession = 1:length(self.sessionImg)
               
               sessionTable = self.sessionImg(iSession).output_data;
               sessionName = sprintf('Session%02d', iSession);
               Session = repmat({sessionName}, size(sessionTable,1), 1);
               sessionTable = [Session, sessionTable];
               dataTable = [dataTable; sessionTable];
           end
            
        end
        
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
                
        function generate_sessions(self, refImg)
            
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
                self.sessionData, refImg);
            
        end
        
    end
    
    % ================================================================== %
    
    methods (Static, Hidden)
        
    end
    
    % ================================================================== %
    
end

