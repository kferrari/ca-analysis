ExperimentFolder = 'D:\Experiments\Astrocyte Calcium\Plasticity\';

AnimalNames = {
    'GC07',...   %control
    'GC12',...    %control
    'GC14',...    %control
    'RG02',...      %control
    'KF04',...      %control
    'KF05',...       %control
    };

ScoreSheetNames = {
    'GC07_Scoresheet_Imaging.xls',...
    'GC12_Scoresheet_Imaging.xls',...
    'GC14_Scoresheet_Imaging.xls',...
    'RG02_Scoresheet_Imaging.xls',...
    'KF04_Scoresheet_Imaging.xls',...
    'KF05_Scoresheet_Imaging.xls',...
    };

spot1Path = {
    'GC07\imaging\2014_05_05_baseline\spot1C1_TrimNostim\highres_spot1C1_nostim025.tif',...
    'GC12\imaging\14_08_04_baseline\spot1G_TrimNostim\highres_spot1G_nostim001.tif',...
    'GC14\imaging\14_08_05_baseline\spot1G_TrimNostim\highres_spot1G_nostim049.tif',...
    'RG02\imaging\14_05_06_baseline\spot1G_TrimNostim\highres_spot1G_nostim031.tif',...
    'KF04\imaging\14_08_28_baseline\spot1C1_TrimNostim\highres_spot1C1_nostim049.tif',...
    'KF05\imaging\14_08_28_baseline\spot1Delta_TrimNostim\highres_spot1Delta_nostim001.tif',...
    };

spot2Path = {
    'GC07\imaging\2014_05_05_baseline\spot2C1_TrimNostim\highres_spot2C1_nostim026.tif',...
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
        '150811_ResultsTable.mat');
    
    if exist(savepath, 'file')
        continue
    end
    
    [~,spot1] = scim.scim_openTif([ExperimentFolder, ...
        spot1Path{iAnimal}]);
    [~,spot2] = scim.scim_openTif([ExperimentFolder, ...
        spot1Path{iAnimal}]);

    spot1Ref = mean(squeeze(spot1(:,:,1,:)),3);
    spot2Ref = mean(squeeze(spot2(:,:,1,:)),3);
    
    refImg = cat(3, spot1Ref, spot2Ref);
    
    AnimalObj = Animal(ExperimentFolder, ...
                'treated', ...
                AnimalNames(iAnimal), ...
                ScoreSheetFolders(iAnimal));
    
    if ~strcmp(AnimalObj.state, 'preprocessed')
        AnimalObj.preprocess(refImg);
    end
    
    if strcmpi(AnimalNames{iAnimal}, 'gc09')
        nBaseSessions = 2;
    else
        nBaseSessions = 3;
    end
        
    AnimalObj.process(nBaseSessions, useParallel);
    
    % Save data, because of RAM problem
    dataTable = AnimalObj.output_data();
    save(savepath, 'dataTable', '-v7.3');
    
    clearvars -except AnimalNames ExperimentFolder ScoreSheetNames spot1Path ...
        spot2Path ScoreSheetFolders useParallel
end

newTable = table();
dataTable = table();
for iAnimal = 1:numel(AnimalNames)
    
    savepath = fullfile(ExperimentFolder, AnimalNames{iAnimal}, ...
        '150811_ResultsTable.mat');
    load(savepath)
    
    Animal = repmat(AnimalNames(iAnimal), size(dataTable, 1), 1);
    animalCol = table(Animal);
    dataTable = [animalCol, dataTable];
    newTable = [dataTable; newTable];
    
end

writetable(newTable, fullfile(ExperimentFolder, 'Results', ...
    'Table_control_animals_sessions.csv'), 'Delimiter', ',');