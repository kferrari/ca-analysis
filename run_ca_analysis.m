ExperimentFolder = 'D:\Experiments\Astrocyte Calcium\Plasticity\';

AnimalNames = {
%    'GC603',...   %treated
%     'GC604',...    %treated
%     'GC605',...    %treated
     'GC09',...      %treated
%     'GC13',...      %treated
%     'KF3',...       %treated
    };

ScoreSheetNames = {
%    'GC603_Scoresheet_Imaging_Test.xls'
%     'GC603_Scoresheet_Imaging.xls',...
%     'GC604_Scoresheet_Imaging.xls',...
%     'GC605_Scoresheet_Imaging.xls',...
     'GC09_Scoresheet_Imaging.xls',...
%     'GC13_Scoresheet_Imaging.xls',...
%     'KF3_Scoresheet_Imaging.xls',...
    };


ScoreSheetFolder = ...
    'D:\Experiments\Astrocyte Calcium\Plasticity\Scoresheets';

ScoreSheetFolders = fullfile(ScoreSheetFolder, ScoreSheetNames);


for iAnimal = 1:numel(AnimalNames)
    
    AnimalObj = Animal(ExperimentFolder, ...
                'treated', ...
                AnimalNames(iAnimal), ...
                ScoreSheetFolders(iAnimal));
    AnimalObj.preprocess();
    AnimalObj.process()
    
    %testAnimal.output_data()
    
    clearvars Animal
end