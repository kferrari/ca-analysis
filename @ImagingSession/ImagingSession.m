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
            [experimentDir, sessionDataIn, refImg] = ...
                utils.parse_opt_args({[], '', []}, varargin);
             
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
                
                generate_data(ImagingSessionObj, experimentDir, refImg)
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
            
            generate_data(ImagingSessionObj, experimentDir, refImg)
            
        end
        
        % -------------------------------------------------------------- %
                
        function process(self, varargin)
            
            % Parse arguments
            [nBaseSessions, useParallel] = ...
                utils.parse_opt_args({1, 1}, varargin);           
            
            % Find ROIs for the baseline sessions
            roiMask = [];
            for iBase = 1:nBaseSessions
                for iSpot = 1:numel(self(iBase).imaging)
                    self(iBase).imaging(iSpot).data.process(...
                        useParallel, 'find');
                    
                    % Attempt to combine the masks into a 3d array
                    nChilds = self(iBase).imaging(iSpot).data.nChildren;
                    
                    for iChild = 1:nChilds
                        nScans = numel(self(iBase).imaging(iSpot).data...
                            .children{iChild});
                        for iScan = 1:nScans
                            roiMask(:,:,end+1) = ...
                            any(self(iBase).imaging(iSpot).data.children...
                            {iChild}(iScan).calcFindROIs.get_roiMask(), 3);
                        end
                    end
                end
            end
            
            baselineRoiMask = any(roiMask, 3);
            
            nSessions = numel(self);
            for iSession = nBaseSessions+1:nSessions
                 
                
            end
            
        end
        
        % -------------------------------------------------------------- %
        
        function sessionTable = output_data(self, varargin)
            
            sessionTable = table();
            numSpots = numel(self.imaging);
            for iSpot = 1:numSpots
                spotName = self.imaging(iSpot).spotID;
                spotTable = table();
                
                numChilds = self.imaging(iSpot).data.nChildren;
                for iChild = 1:numChilds
                    childTable = table();
                    childName = self.imaging(iSpot).data.children{iChild}(1)...
                        .name;
                    
                    numScans = numel(self.imaging(iSpot).data.children{iChild});
                    for iScan = 1:numScans
                        scanTable = table();
                        scanName = sprintf('Trial%02d', iScan);
                        tempData = self.imaging(iSpot).data.children{iChild}(iScan)...
                            .calcMeasureROIs.data.peakDataSort;
                        
                        % Verify that scan was already processed
                        scanState = self.imaging(iSpot).data.children{iChild}(iScan).state;
                        if strcmpi(scanState, 'raw')
                            warning('ImagingSession:output_data:notProcessed', ...
                                'Please process scans first');
                        end
                        
                        if isempty(tempData)
                            continue
                        end
                        
                        partTable = table();
                        numROIs = numel(tempData);
                        for iROI = 1:numROIs
                            roiTable = table();
                            roiName = sprintf('ROI%03d', iROI);
                            if ~isempty(tempData{iROI})
                                roiTable = struct2table(tempData{iROI});
                                ROI = repmat({roiName},size(roiTable,1),1);
                                roiCol = table(ROI);
                                roiTable = [roiCol roiTable];
                                
                                partTable = [partTable; roiTable];
                            end
                        end
                        
                        Trial = repmat({scanName},size(partTable,1),1);
                        trialCol = table(Trial);
                        partTable = [trialCol partTable];
                        
                        scanTable = [scanTable; partTable];
                        
                    end
                    
                    Condition = repmat({childName},size(childTable,1),1);
                    conditionCol = table(Condition);
                    childTable = [conditionCol childTable];
                    
                    spotTable = [childTable; scanTable];
                end
                
                Spot = repmat({spotName},size(spotTable,1),1);
                spotCol = table(Spot);
                spotTable = [spotCol spotTable];
                
                sessionTable = [sessionTable; spotTable];
                    
            end
            
        end
        
        % -------------------------------------------------------------- %
        
    end
    
    % ================================================================== %
    
    methods (Access=protected)
                
        function generate_data(self, varargin)
            
            % Parse arguments
            [experimentDir, refImg] =  utils.parse_opt_args({'', []}, ...
                varargin);
            
           if ~isscalar(self)
               arrayfun(@(x) generate_data(x, varargin{:}), self)
               return
           end
           
           spotIDs = unique(self.sessionData{:,'SpotIDs'});
           
           for iSpot = 1:numel(spotIDs)
               
               spotRefImg = refImg(:,:,iSpot);
               
               currSpot = spotIDs{iSpot};
               tempDataIdx = strcmp(self.sessionData{:,'SpotIDs'},...
                   currSpot);
               tempData = self.sessionData(tempDataIdx, :);
               
               % Store SpotID
               self.imaging(iSpot).spotID = spotIDs{iSpot};
               
               % Generate RawImg objects
               pattern = 'lowres*';
               paths = fullfile(experimentDir, ...
                   tempData{:,'RelativePath'});
               
               calibration = load(['D:\Code\Matlab\2p-img-analysis\', ...
                   'tests\res\calibration.mat']);
               calibration = calibration.self;
               
               channels = struct('AstrocyteCytoCalcium', 1);
               configFindIn = ConfigFindROIsFLIKA();
               configFindIn.discardBorderROIs = true;
               configMeasureIn = ConfigMeasureROIsClsfy();
               configCSIn = ConfigCellScan(configFindIn, configMeasureIn);
               
               for i = 1:numel(paths)
                   fileList = dir(fullfile(paths{i}, pattern));
                   %refImgList = dir(fullfile(paths{i}, 'highres*'));
                   filePaths = fullfile(paths{i}, {fileList.name});
                   %refImgPath = fullfile(paths{i}, {refImgList.name});
                   
                   tempImgData = SCIM_Tif(filePaths, channels, ...
                       calibration);
                   tempImgData = tempImgData.motion_correct(...
                      'refImg', spotRefImg);
                   tempCS{i} = CellScan('name', tempImgData, ...
                       configCSIn, 1);
               end
               
               tempImgGroup = ImgGroup('Conditions');
               tempImgGroup.add(tempCS);
               
               self.imaging(iSpot).data = tempImgGroup;
               
           end
            
        end
        
    end
    
    % ================================================================== %
    
    methods (Static, Hidden)
        
    end
    
    % ================================================================== %
    
end

