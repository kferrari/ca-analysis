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
            [experimentDir, sessionDataIn, refImg, useHandROI, ROIFolder] = ...
                utils.parse_opt_args({[], '', [], false, ''}, varargin);
            
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
                
                generate_data(ImagingSessionObj, experimentDir, refImg, ...
                    useHandROI, ROIFolder)
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
            
            generate_data(ImagingSessionObj, experimentDir, refImg, ...
                useHandROI, ROIFolder)
            
        end
        
        % -------------------------------------------------------------- %
        
        function process(self, varargin)
            
            % Parse arguments
            [nBaseSessions, useParallel, useHandROI, ExperimentFolder] = ...
                utils.parse_opt_args({1, 1, 0, ''}, varargin);
            
            % Determine if hand-clicked ROIs are provided
            if ~useHandROI
                
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
                                roiMask(:,:,iSpot,end+1) = ...
                                    any(self(iBase).imaging(iSpot).data.children...
                                    {iChild}(iScan).calcFindROIs.get_roiMask(), 3);
                            end
                        end
                    end
                end
                
                % Combine ROI masks
                dims = size(roiMask);
                baselineRoiMask = zeros(dims(1),dims(2),dims(3));
                for iSpot = 1:numel(self(iBase).imaging)
                    mapSum = sum(squeeze(roiMask(:,:,iSpot,:)),3);
                    mapNorm = mapSum - min(mapSum(:))./ ...
                        (max(mapSum(:)) - min(mapSum(:)));
                    mapThresh = mapNorm > 0.4;
                    mapEroded = imerode(mapThresh, strel('disk', 2));
                    mapDilated = imdilate(mapEroded, strel('disk', 2));
                    baselineRoiMask(:,:,iSpot) = mapDilated;
                end
                
                % Update ROI masks
                nSessions = numel(self);
                for iSession = 1:nSessions
                    for iSpot = 1:numel(self(iSession).imaging)
                        nChilds = self(iSession).imaging(iSpot).data.nChildren;
                        for iChild = 1:nChilds
                            nScans = numel(self(iSession).imaging(iSpot).data...
                                .children{iChild});
                            for iScan = 1:nScans
                                currConf = self(iSession).imaging(iSpot).data...
                                    .children{iChild}(iScan).calcFindROIs.config;
                                newCalcObj = self(iSession).imaging(iSpot).data...
                                    .children{iChild}(iScan).calcFindROIs...
                                    .data.update_roi_mask(baselineRoiMask(...
                                    :,:,iSpot), {''});
                                self(iSession).imaging(iSpot).data.children...
                                    {iChild}(iScan).calcFindROIs = ...
                                    CalcFindROIsFLIKA(currConf, newCalcObj);
                                
                                % Save ROI mask
                                maskFolder = fullfile(ExperimentFolder, ...
                                    fileparts(char(self(iSession).sessionData{1,'RelativePath'})));
                                maskName = ...
                                    [self(iSession).imaging(iSpot).spotID, ...
                                    '_longROImask.tif'];
                                maskFile = fullfile(maskFolder, maskName);
                                
                                imwrite(baselineRoiMask(:,:,iSpot), maskFile);
                                
                            end
                        end
                    end
                end
            else
                % Run the dummy findROIs processing
                nSessions = numel(self);
                for iSess = 1:nSessions
                    for iSpot = 1:numel(self(iSess).imaging)
                        self(iSess).imaging(iSpot).data.process(...
                            useParallel, 'find');
                    end
                end
            end
            
            % Run the actual measuring step
            nSessions = numel(self);
            for iSess = 1:nSessions
                for iSpot = 1:numel(self(iSess).imaging)
                    self(iSess).imaging(iSpot).data.process(...
                        useParallel, 'measure');
                end
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
                        tempCentroids = self.imaging(iSpot).data.children{iChild}(iScan)...
                            .calcMeasureROIs.data.roiCentroids;
                        
                        % Verify that scan was already processed
                        scanState = self.imaging(iSpot).data.children{iChild}(iScan).state;
                        if strcmpi(scanState, 'raw')
                            warning('ImagingSession:output_data:notProcessed', ...
                                'Please process scans first');
                        end
                        
                        if isempty(tempData)
                            continue
                        end
                        
                        numROIs = numel(tempData);
                        for iROI = 1:numROIs
                            roiTable = table();

                            if ~isempty(tempData{iROI})
                                roidata = tempData{iROI};
                                [roidata(:).Centroid] = deal(tempCentroids(iROI));
                                roiTable = struct2table(roidata); 
                                scanTable = [scanTable; roiTable];
                            end
                        end
                        
                        Trial = repmat({scanName},size(scanTable,1),1);
                        trialCol = table(Trial);
                        scanTable = [trialCol scanTable];
                        
                        if ~isempty(scanTable)
                            childTable = [childTable; scanTable];
                        end
                    end
                    
                    Condition = repmat({childName},size(childTable,1),1);
                    conditionCol = table(Condition);
                    childTable = [conditionCol childTable];
                    
                    if ~isempty(childTable)
                        spotTable = [spotTable; childTable];
                    end
                end
                
                Spot = repmat({spotName},size(spotTable,1),1);
                spotCol = table(Spot);
                spotTable = [spotCol spotTable];
                
                if ~isempty(spotTable)
                    sessionTable = [sessionTable; spotTable];
                end
            end
            
        end
        
        % -------------------------------------------------------------- %
        
    end
    
    % ================================================================== %
    
    methods (Access=protected)
        
        function generate_data(self, varargin)
            
            % Parse arguments
            [experimentDir, refImg, useHandROI, ROIFolder] =  ...
                utils.parse_opt_args({'', [], false, ''}, varargin);
            
            if ~isscalar(self)
                arrayfun(@(x) generate_data(x, varargin{:}), self)
                return
            end
            
            spotIDs = unique(self.sessionData{:,'SpotIDs'});
            
            for iSpot = 1:numel(spotIDs)
                
                spotRefImg = refImg(:,:,iSpot);
                
                currSpot = spotIDs{iSpot};
                
                if ~isempty(strfind(currSpot, 'spot1'))
                    currROIFolder = fullfile(ROIFolder, 'spot1');
                elseif ~isempty(strfind(currSpot, 'spot2'))
                    currROIFolder = fullfile(ROIFolder, 'spot2');
                end
                
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
                
                if useHandROI
                    % Generate zip file path
                    zipList = dir(fullfile(currROIFolder, '*.zip'));
                    zipFilePath = fullfile(currROIFolder, zipList.name);
                    configFindIn = ...
                        ConfigFindROIsDummy.from_ImageJ(zipFilePath,512,512);
                else
                    configFindIn = ConfigFindROIsFLIKA();
                    configFindIn.discardBorderROIs = true;
                end
                configMeasureIn = ConfigMeasureROIsClsfy();
                configCSIn = ConfigCellScan(configFindIn, configMeasureIn);
                
                tempCS = {};
                counter = 1;
                for i = 1:numel(paths)
                    fileList = dir(fullfile(paths{i}, pattern));
                    filePaths = fullfile(paths{i}, {fileList.name});
                    
                    % Find the current condition
                    if any(strfind(paths{i}, 'TrimSpareStim'))
                        %name = 'TrimSpareStim';
                        continue
                    elseif any(strfind(paths{i}, 'TrimStim'))
                        name = 'TrimStim';
                    elseif any(strfind(paths{i}, 'TrimNostim'))
                        name = 'TrimNostim';
                    end
                    
                    tempImgData = SCIM_Tif(filePaths, channels, ...
                        calibration);
                    tempImgData = tempImgData.motion_correct(...
                        'refImg', spotRefImg);
                    
                    tempCS{counter} = CellScan(name, tempImgData, ...
                        configCSIn, 1);
                    counter = counter+1;
                end
                
                if ~isempty(tempCS)
                    tempImgGroup = ImgGroup('Conditions');
                    tempImgGroup.add(tempCS);
                    
                    self.imaging(iSpot).data = tempImgGroup;
                end
            end
            
        end
        
    end
    
    % ================================================================== %
    
    methods (Static, Hidden)
        
    end
    
    % ================================================================== %
    
end

