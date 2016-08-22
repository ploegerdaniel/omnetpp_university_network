function [moduleFilter,statisticNameFilter,value] = importRawSca(filename, startRow, endRow)
%IMPORTFILE Import numeric data from a text file as column vectors.
%   [MODULEFILTER,STATISTICNAMEFILTER,VALUE] = IMPORTFILE(FILENAME) Reads
%   data from text file FILENAME for the default selection.
%
%   [MODULEFILTER,STATISTICNAMEFILTER,VALUE] = IMPORTFILE(FILENAME,
%   STARTROW, ENDROW) Reads data from rows STARTROW through ENDROW of text
%   file FILENAME.
%
% Example:
%   [moduleFilter,statisticNameFilter,value] = importfile('_on0-0.sca',1, 2507);
%
%    See also TEXTSCAN.

% Auto-generated by MATLAB on 2016/08/21 18:28:57

%% Initialize variables.
delimiter = '\t';
if nargin<=2
    startRow = 1;
    endRow = inf;
end

%% Format string for each line of text:
%   column1: text (%q)
%	column2: text (%q)
%   column3: double (%f)
% For more information, see the TEXTSCAN documentation.
formatSpec = '%q%q%q%[^\n\r]';

%% Open the text file.
fileID = fopen(filename,'r');

%% Read columns of data according to format string.
% This call is based on the structure of the file used to generate this
% code. If an error occurs for a different file, try regenerating the code
% from the Import Tool.
textscan(fileID, '%[^\n\r]', startRow(1)-1, 'WhiteSpace', '', 'ReturnOnError', false);
dataArray = textscan(fileID, formatSpec, endRow(1)-startRow(1)+1, 'Delimiter', delimiter, 'EmptyValue' ,NaN,'ReturnOnError', false);
for block=2:length(startRow)
    frewind(fileID);
    textscan(fileID, '%[^\n\r]', startRow(block)-1, 'WhiteSpace', '', 'ReturnOnError', false);
    dataArrayBlock = textscan(fileID, formatSpec, endRow(block)-startRow(block)+1, 'Delimiter', delimiter, 'EmptyValue' ,NaN,'ReturnOnError', false);
    for col=1:length(dataArray)
        dataArray{col} = [dataArray{col};dataArrayBlock{col}];
    end
end

%% Close the text file.
fclose(fileID);

%% Post processing for unimportable data.
% No unimportable data rules were applied during the import, so no post
% processing code is included. To generate code which works for
% unimportable data, select unimportable cells in a file and regenerate the
% script.

%% Allocate imported array to column variable names
moduleFilter = dataArray{:, 1};
statisticNameFilter = dataArray{:, 2};
value = dataArray{:, 3};


