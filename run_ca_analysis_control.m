ExperimentFolder = 'D:\Experiments\Astrocyte Calcium\Plasticity\';

ZipFolder = 'P:\_Group\Projects\Astrocyte Calcium\Current Milestones\Astrocyte Calcium Imaging During Plasticity\Imaging Data\ImagesforClicking\Controls';

AnimalNames = {
    'GC12',...    %control
    'GC14',...    %control
    'RG02',...      %control
    'KF04',...      %control
    'KF05',...       %control
    };

ScoreSheetNames = {
    'GC12_Scoresheet_Imaging.xls',...
    'GC14_Scoresheet_Imaging.xls',...
    'RG02_Scoresheet_Imaging.xls',...
    'KF04_Scoresheet_Imaging.xls',...
    'KF05_Scoresheet_Imaging.xls',...
    };

spot1Path = {
    'GC12\imaging\14_08_04_baseline\spot1G_TrimNostim\highres_spot1G_nostim001.tif',...
    'GC14\imaging\14_08_05_baseline\spot1G_TrimNostim\highres_spot1G_nostim049.tif',...
    'RG02\imaging\14_05_06_baseline\spot1G_TrimNostim\highres_spot1G_nostim031.tif',...
    'KF04\imaging\14_08_28_baseline\spot1C1_TrimNostim\highres_spot1C1_nostim049.tif',...
    'KF05\imaging\14_08_28_baseline\spot1Delta_TrimNostim\highres_spot1Delta_nostim001.tif',...
    };

spot2Path = {
    'GC12\imaging\14_08_04_baseline\spot2G_TrimNostim\highres_spot2G_nostim045.tif',...
    'GC14\imaging\14_08_05_baseline\spot2G_TrimNostim\highres_spot2G_nostim091.tif',...
    'RG02\imaging\14_05_06_baseline\spot2G_TrimNostim\highres_spot2G_nostim001.tif',...
    'KF04\imaging\14_08_28_baseline\Spot2C1_TrimNostim\highres_spot2C1_nostim092.tif',...
    'KF05\imaging\14_08_28_baseline\spot2Delta_TrimNostim\highres_spot2Delta_nostim043.tif',...
    };


ScoreSheetFolder = ...
    'D:\Experiments\Astrocyte Calcium\Plasticity\Scoresheets';

ScoreSheetFolders = fullfile(ScoreSheetFolder, ScoreSheetNames);

useParallel = true;

for iAnimal = 1:numel(AnimalNames)
    
    savepath = fullfile(ExperimentFolder, AnimalNames{iAnimal}, ...
        '150902_ResultsTable_handclicked.mat');
    
    if exist(savepath, 'file')
        continue
    end
    
    [~,spot1] = scim.scim_openTif([ExperimentFolder, ...
        spot1Path{iAnimal}]);
    [~,spot2] = scim.scim_openTif([ExperimentFolder, ...
        spot2Path{iAnimal}]);

    spot1Ref = mean(squeeze(spot1(:,:,1,:)),3);
    spot2Ref = mean(squeeze(spot2(:,:,1,:)),3);
    
    refImg = cat(3, spot1Ref, spot2Ref);
    
    AnimalObj = Animal(ExperimentFolder, ...
                'treated', ...
                AnimalNames(iAnimal), ...
                ScoreSheetFolders(iAnimal));
    
    useHandROIs = true;
    currROIFolder = fullfile(ZipFolder, AnimalNames{iAnimal});
    
    if ~strcmp(AnimalObj.state, 'preprocessed')
        AnimalObj.preprocess(refImg, useHandROIs, currROIFolder);
    end
    
    nBaseSessions = 3;
    
    AnimalObj.process(nBaseSessions, useParallel, useHandROIs);
    
    % Save data, because of RAM problem
    dataTableTemp = AnimalObj.output_data();
    save(savepath, 'dataTableTemp', '-v7.3');
    
    clearvars -except AnimalNames ExperimentFolder ScoreSheetNames spot1Path ...
        spot2Path ScoreSheetFolders useParallel useHandROIs ZipFolder
end

newTable = table();
dataTable = table();
for iAnimal = 1:numel(AnimalNames)
    
    savepath = fullfile(ExperimentFolder, AnimalNames{iAnimal}, ...
        '150902_ResultsTable_handclicked.mat');
    load(savepath)
    
    Animal = repmat(AnimalNames(iAnimal), size(dataTableTemp, 1), 1);
    animalCol = table(Animal);
    dataTable = [animalCol, dataTableTemp];
    newTable = [newTable; dataTable];
    
end

% writetable(newTable, fullfile(ExperimentFolder, 'Results', ...
%     'Table_control_animals_sessions_handclicked.csv'), 'Delimiter', ',');