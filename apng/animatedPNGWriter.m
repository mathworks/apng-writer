classdef animatedPNGWriter < handle
    % animatedPNGWriter Creates animated PNG files
    %   animatedPNGWriter creates animated PNG (APNG) files. These are
    %   files that animate, similar to GIFs, when displayed in most web
    %   browsers. Unlike GIF, APNG supports 24-bit color. It also tends to
    %   result in smaller file sizes.
    %
    %   NOTE: animatedPNGWriter requires the utility "APNG Assembler"
    %   from here: http://apngasm.sourceforge.net. When you call
    %   animatedPNGWriter, it will attempt to automatically download that
    %   program if it does not already exist in the expected location.
    %
    %   To create an APNG file, follow these steps:
    %
    %   1. Create an animatedPNGWriter object.
    %
    %        w = animatedPNGWriter(output_filename);
    %
    %   2. Set desired object properties, such as FramesPerSecond,
    %   NumLoops, or RepeatLoopDelay:
    %
    %        w.FramesPerSecond = 20;
    %        w.NumLoops = 5;
    %        w.RepeatLoopDelay = 1;
    %
    %   3. Add image frames. Note that each image added must have the same
    %      number of rows and columns.
    %
    %        addframe(w,frame_k);
    %
    %   4. After all the frames have been added, call finish.
    %
    %        finish(w);
    %
    %   TIP: Use print with the -RGBImage option to get an image from a
    %   MATLAB figure that you can add to an APNG file.
    %
    % EXAMPLE
    %
    % Create an APNG that shows an animated sine wave created using the
    % MATLAB function animatedline.
    %
    %   w = animatedPNGWriter('animated_line_apng.png');
    %
    %   h = animatedline('LineWidth',1.5,'Color',lines(1));
    %   axis([0,4*pi,-1,1])
    %   numpoints = 10000;
    %   x = linspace(0,4*pi,numpoints);
    %   y = sin(x);
    %   for k = 1:500:numpoints-499
    %       xvec = x(k:k+499);
    %       yvec = y(k:k+499);
    %       addpoints(h,xvec,yvec)
    %       drawnow
    %       addframe(w,print('-r200','-RGBImage'));
    %   end
    %
    %   finish(w);
    
    % Copyright 2019 The MathWorks, Inc.
    
    properties (SetAccess = private)
        % Number of columns in each frame
        Width = []
        
        % Number of rows in each frame
        Height = []
        
        % Number of frames added so far
        NumFrames = 0
        
        % True if the APNG file has been created.
        Finished = false;
        
        % Filename of the first frame
        FirstFrameFile = ""
        
        % Filename of the last frame
        LastFrameFile = ""
    end
    
    properties
        % Number of frames per second (default is 10, maximum is 50)
        FramesPerSecond = 10
        
        % Number of times to repeat the animation (default is unlimited)
        NumLoops = Inf
        
        % Number of seconds before starting the next loop
        LoopRepeatDelay = 2
        
        % If true, first frame is used only as the static image
        SkipFirstFrame = false
        
        % Output APGN file
        OutputFile
    end
    
    properties (SetAccess = private)
        % Folder used to save individual frame files
        TemporaryFolder = ""
    end
    
    methods
        function writer = animatedPNGWriter(output_file)
            % animatedPNGWriter Creates animated PNG (APNG) files
            %   writer = animatedPNGWriter(output_filename) returns an
            %   animatedPNGWriter object for creating an APNG file with the
            %   specified filename.
            
            narginchk(1,Inf);
            
            animatedPNGWriter.getAPNGAssembler;
            
            writer.TemporaryFolder = tempname;
            s = mkdir(writer.TemporaryFolder);
            if (s ~= 1)
                error('animatedPNGWriter:TempFolderCreateFailure',...
                    'Could not create temporary folder: %s', ...
                    writer.TemporaryFolder)
            end
            writer.OutputFile = output_file;
        end
        
        function set.FramesPerSecond(writer,fps)
            % 50 is the maximum value for frames per second.
            writer.FramesPerSecond = min(fps,50);
        end
        
        function addframe(w,varargin)
            % addframe Add an APNG frame
            %   addframe(writer,A) adds an images as a frame to the APNG
            %   writer. The image can be a grayscale (MxN) or RGB (MxNx3)
            %   image.
            %
            %   addframe(writer,X,map) adds an indexed image as a frame to
            %   the APNG writer.
            
            if w.Finished
                error('animatedPNGWriter:AddFrameAfterFinish',...
                    'Cannot add frames after output file creation is finished.');
            end
            
            narginchk(2,Inf);
            next_frame_number = w.NumFrames + 1;
            filename = sprintf("frame_%09d.png",next_frame_number);
            filename = fullfile(w.TemporaryFolder,filename);
            A = varargin{1};
            if isempty(w.Width)
                w.Width = size(A,2);
                w.Height = size(A,1);
            else
                if (w.Width ~= size(A,2)) || (w.Height ~= size(A,1))
                    error('animatedPNGWriter:SizeMismatch',...
                        'All frames must have the same number of rows and columns.');
                end
            end
            imwrite_args{1} = A;
            if (length(varargin) == 1)
                % addframe(w,A)
                % Translate to imwrite(A,filename,'png')
                imwrite_args{2} = filename;
                imwrite_args{3} = 'png';
            else
                % There are at least two arguments. See if the second
                % argument is a colormap.
                if isfloat(varargin{2}) && ismatrix(varargin{2}) && ...
                        (size(varargin{2},2) == 3)
                    % Translate to imwrite(X,map,filename,'png',Name,Value)
                    map = varargin{2};
                    imwrite_args{2} = map;
                    imwrite_args{3} = filename;
                    imwrite_args{4} = 'png';
                    imwrite_args = [imwrite_args varargin(3:end)];
                else
                    % Translate to imwrite(A,filename,'png',Name,Value)
                    imwrite_args{2} = filename;
                    imwrite_args{3} = 'png';
                    imwrite_args = [imwrite_args varargin(2:end)];
                end
            end
            
            imwrite(imwrite_args{:});
            w.NumFrames = w.NumFrames + 1;
            if w.NumFrames == 1
                w.FirstFrameFile = filename;
            end
            w.LastFrameFile = filename;
        end
        
        function finish(writer)
            % finish Assemble the frames into the final APNG file
            %   finish(writer) gathers the individual images frames and
            %   assembles them into the final APNG file. After calling
            %   finish(writer), no more frames can be added.
            
            if writer.Finished
                error('animatedPNGWriter:FinishTwice',...
                    'finish has already been called.')
            end
            
            % Write control file to specify the delay following the final
            % frame.
            tol = 1/50;
            [num,den] = rat(writer.LoopRepeatDelay,tol);
            [path,file,~] = fileparts(writer.LastFrameFile);
            last_frame_delay_file = fullfile(path,file + ".txt");
            fid = fopen(last_frame_delay_file,'w');
            if (fid == -1)
                warning("animatedPNGWriter:FileDelayFile",...
                    "Could not create delay control file for final frame.");
            else
                fprintf(fid,"delay=%d/%d",num,den);
                fclose(fid);
            end
            
            system_call = systemCall(writer);
            status = system(system_call);
            if (status ~= 0)
                error('animatedPNGWriter:AssemblerError',...
                    'APNG assembler failed to combine the frames.');
            end
            
            writer.Finished = true;
            cleanup(writer)
        end
    end
    
    methods (Access = private)
        
        function cleanup(writer)
            % cleanup Remove temporary files and folders
            %   cleanup(writer) removes temporary files and folders created
            %   by the animatedPNGWriter object.
            
            if exist(writer.TemporaryFolder,'dir')
                s = rmdir(writer.TemporaryFolder,'s');
                if (s ~= 1)
                    warning('animatedPNGWriter:TempFolderRemoveFailure',...
                        'Could not remove temporary folder: %s',...
                        writer.TemporaryFolder);
                else
                    writer.TemporaryFolder = "";
                end
            end
        end
        
    end
    
    methods (Static)
        function s = apngAssemblerProgramInfo
            writer_path = fileparts(mfilename('fullpath'));
            
            switch computer
                
                case 'PCWIN64'
                    
                    s.Folder = fullfile(writer_path,'win');
                    s.URL = 'https://sourceforge.net/projects/apngasm/files/2.91/apngasm-2.91-bin-win64.zip/download';
                    s.Name = 'apngasm64.exe';
                    s.ZipFilename = 'apngasm-2.91-bin-win64.zip';
                    
                case 'MACI64'
                    
                    s.Folder = fullfile(writer_path,'mac');
                    s.URL = 'https://sourceforge.net/projects/apngasm/files/2.91/apngasm-2.91-bin-macos.zip/download';
                    s.Name = 'apngasm';
                    s.ZipFilename = 'apngasm-2.91-bin-macos.zip';
                    
                case 'GLNXA64'
                    
                    s.Folder = fullfile(writer_path,'linux');
                    s.URL = 'https://sourceforge.net/projects/apngasm/files/2.91/apngasm-2.91-bin-linux.zip/download';
                    s.Name = 'apngasm';
                    s.ZipFilename = 'apngasm-2.91-bin-linux.zip';
                    
                otherwise
                    
                    error('animatedPNGWriter:UnrecognizedComputer',...
                        'Unrecognized computer type.');
                    
            end
            
            s.FullPath = fullfile(s.Folder,s.Name);
        end
        
        function getAPNGAssembler
            %getAPNGAssembler Download the APNG Assembler program.
            
            program_info = animatedPNGWriter.apngAssemblerProgramInfo;
            
            if exist(program_info.FullPath,'file')
                return
            end
            
            if ~exist(program_info.Folder,'dir')
                status = mkdir(program_info.Folder);
                if ~status
                    error('animatedPNGWriter:ProgramFolderCreationFault',...
                        'Could not create folder for APNG Assembler program.');
                end
            end
            
            full_zip_path = fullfile(program_info.Folder,program_info.ZipFilename);
            fprintf('Downloading APNG Assembler program ...');
            websave(full_zip_path,program_info.URL);
            fprintf(' download complete.\n')
            unzip(full_zip_path,program_info.Folder);
            delete(full_zip_path);
        end
    end
end

function call = systemCall(w)
program_info = animatedPNGWriter.apngAssemblerProgramInfo;
if ispc
    redirect = "> nul";
else
    redirect = ">> /dev/null";
end
call = sprintf("""%s"" ""%s"" ""%s"" %s", program_info.FullPath, ...
    w.OutputFile, w.FirstFrameFile,redirect);
end


