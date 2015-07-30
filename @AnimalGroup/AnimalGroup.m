classdef AnimalGroup < handle
    %AnimalGroup Summary of this class goes here
    %   Detailed explanation goes here
    
    % ================================================================== %
    
    properties
        
        % Experiment info
        treatment 
        
        % Data info
        experimentDir
        
    end
    
    % ------------------------------------------------------------------ %
    
    properties (Constant, Access = protected)
        % none I could think of yet
    end
    
    % ================================================================== %
    
    methods
        
        function AnimalGroupObj = AnimalGroup(varargin)
            
            % Parse arguments
            [experimentDirIn, treatmentIn] = ...
                utils.parse_opt_args({'', ''}, varargin);
             
            % Work out the current recursion depth
            if utils.is_deeper_than('AnimalGroup.AnimalGroup')
                return;
            end
            
            AnimalGroupObj.treatment = treatmentIn;
            AnimalGroupObj.experimentDir = experimentDirIn;
            
        end
        
        % -------------------------------------------------------------- %
        
        output_data(self, varargin)
        
    end
    
    % ================================================================== %
    
    methods (Access=protected)
        
    end
    
    % ================================================================== %
    
    methods (Static, Hidden)
        
    end
    
    % ================================================================== %
    
end

