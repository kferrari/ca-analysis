ExperimentFolder = 'D:\Experiments\Astrocyte Calcium\Plasticity\';

AnimalNames = {
    'GC603',...   %treated
    'GC604',...    %treated
    'GC605',...    %treated
    'GC09',...      %treated
    'GC13',...      %treated
    'KF3',...       %treated
    };

ScoreSheetNames = {
    'GC603_Scoresheet_Imaging.xls',...
    'GC604_Scoresheet_Imaging.xls',...
    'GC605_Scoresheet_Imaging.xls',...
    'GC09_Scoresheet_Imaging.xls',...
    'GC13_Scoresheet_Imaging.xls',...
    'KF3_Scoresheet_Imaging.xls',...
    };

spot1Path = {
    'GC603\imaging\2013_7_3_baseline\spot1D1_TrimNostim\highres_spot1D1_nostim001.tif',...
    'GC604\imaging\2013_7_4_baseline\spot1C1_TrimNostim\highres_spot1C1_nostim002.tif',...
    'GC605\imaging\2013_7_10_baseline\spot1C1_TrimNostim\highres_spot1C1_nostim003.tif',...
    'GC09\imaging\14_08_05_baseline\spot1G_TrimNostim\highres_spot1G_nostim043.tif',...
    'GC13\imaging\14_08_06_baseline\spot1G_TrimNostim\highres_spot1G_nostim001.tif',...
    'KF3\imaging\14_08_04_baseline\spot1E1_TrimNostim\highres_spot1E1_nostim005.tif',...
    };

spot2Path = {
    'GC603\imaging\2013_7_3_baseline\spot2D1_TrimNostim\highres_spot2D1_nostim001.tif',...
    'GC604\imaging\2013_7_4_baseline\spot2C1_TrimNostim\highres_spot2C1_nostim001.tif',...
    'GC605\imaging\2013_7_10_baseline\spot2C1_TrimNostim\highres_spot2C1_nostim006.tif',...
    'GC09\imaging\14_08_05_baseline\spot2G_TrimNostim\highres_spot2G_nostim001.tif',...
    'GC13\imaging\14_08_06_baseline\spot2G_TrimNostim\highres_spot2G_nostim043.tif',...
    'KF3\imaging\14_08_04_baseline\spot2E1_TrimNostim\highres_spot2E1_nostim051.tif',...
    };


ScoreSheetFolder = ...
    'D:\Experiments\Astrocyte Calcium\Plasticity\Scoresheets';

ScoreSheetFolders = fullfile(ScoreSheetFolder, ScoreSheetNames);

useParallel = true;

for iAnimal = 1:numel(AnimalNames)
    
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
    savepath = fullfile(ExperimentFolder, AnimalNames{iAnimal}, ...
        '150811_ResultsTable.mat');
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
    'Table_treated_animals_sessions.csv'), 'Delimiter', ',');