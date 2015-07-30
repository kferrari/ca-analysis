classdef ImagingSession < handle
    %AnimalGroup Summary of this class goes here
    %   Detailed explanation goes here
    
    % ================================================================== %
    
    properties
        
        % basic info for this session
        date
        sessionData
        
        % data reference
        imaging
        
    end
    
    % ================================================================== %
    
    methods
        
        function ImagingSessionObj = ImagingSession(varargin)
            
            % Parse arguments
            [experimentDir, sessionDataIn] = ...
                utils.parse_opt_args({[], ''}, varargin);
             
            % Work out the current recursion depth
            if utils.is_deeper_than('ImagingSession.ImagingSession')
                return;
            end
            
            if isscalar(sessionDataIn)
                
                if iscell(sessionDataIn)
                    sessionDataIn = sessionDataIn{:};
                end
                
                ImagingSessionObj.sessionData = sessionDataIn;
                
                % Convert date number to string (use offset to correct for
                % excel-to-matlab conversion error)
                dateOffset = 693960;
                ImagingSessionObj.date = ...
                    datestr(sessionDataIn{1,'Date'} + ...
                    dateOffset, 'dd-mmm-yy');
                
                generate_data(ImagingSessionObj, experimentDir)
                return
            end
            
            % Treat group as individual animals
            nSessions = numel(sessionDataIn);
            for iSession = nSessions:-1:1
                
                ImagingSessionObj(iSession).sessionData = ...
                    sessionDataIn{iSession};
                
                % Convert date number to string (use offset to correct for
                % excel-to-matlab conversion error)
                dateOffset = 693960;
                ImagingSessionObj(iSession).date = ...
                    datestr(sessionDataIn{iSession}{1,'Date'} + ...
                    dateOffset, 'dd-mmm-yy');
                
            end
            
            generate_data(ImagingSessionObj, experimentDir)
            
        end
        
        % -------------------------------------------------------------- %
        
        function process(self, varargin)
            
           if ~isscalar(self)
                arrayfun(@process, self, 'UniformOutput', false);
                return
           end
           
           self.imaging.data.process(); 
            
        end
        
        % -------------------------------------------------------------- %
        
        output_data(self, varargin)
        
        % -------------------------------------------------------------- %
        
    end
    
    % ================================================================== %
    
    methods (Access=protected)
                
        function generate_data(self, varargin)
            
            % Parse arguments
            [experimentDir] =  utils.parse_opt_args({''}, varargin);
            
           if ~isscalar(self)
               arrayfun(@(x) generate_data(x, experimentDir), self)
               return
           end
           
           spotIDs = unique(self.sessionData{:,'SpotIDs'});
           
           for iSpot = 1:numel(spotIDs)
               
               currSpot = spotIDs{iSpot};
               tempDataIdx = strcmp(self.sessionData{:,'SpotIDs'},...
                   currSpot);
               tempData = self.sessionData(tempDataIdx, :);
               
               % Store SpotID
               self.imaging.spotID = spotIDs{iSpot};
               
               % Generate RawImg objects
               pattern = 'lowres*';
               paths = fullfile(experimentDir, ...
                   tempData{:,'RelativePath'});
               
               calibration = load(['D:\Code\Matlab\2p-img-analysis\', ...
                   'tests\res\calibration.mat']);
               
               channels = struct('AstrocyteCytoCalcium', 1);
               configFindIn = ConfigFindROIsFLIKA();
               configMeasureIn = ConfigMeasureROIsClsfy();
               configCSIn = ConfigCellScan(configFindIn, configMeasureIn);
               
               for i = 1:numel(paths)
                   fileList = dir(fullfile(paths{i}, pattern));
                   %refImgList = dir(fullfile(paths{i}, 'highres*'));
                   filePaths = fullfile(paths{i}, {fileList.name});
                   %refImgPath = fullfile(paths{i}, {refImgList.name});
                   
                   tempImgData = SCIM_Tif(filePaths, channels, ...
                       calibration.self);
                   tempImgData = tempImgData.motion_correct();
                   tempCS{i} = CellScan('name', tempImgData, configCSIn, 1);
               end
               
               tempImgGroup = ImgGroup('Conditions');
               tempImgGroup.add(tempCS);
               
               self.imaging.data = tempImgGroup;
               
           end
            
        end
        
    end
    
    % ================================================================== %
    
    methods (Static, Hidden)
        
    end
    
    % ================================================================== %
    
end

