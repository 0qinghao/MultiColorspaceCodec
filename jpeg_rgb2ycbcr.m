% % https://en.wikipedia.org/wiki/YCbCr
% function ycbcr = jpeg_rgb2ycbcr(rgb)
%     [rr, cc, ~] = size(rgb);
%     ycbcr = rgb;
%     % ycbcr = double(rgb);
%     rgb2ycbcr_mat = [0.299, 0.587, 0.114;
%                 -0.168736, -0.331264, 0.5;
%                 0.5, -0.418688, -0.081312
%                 ]';
%     rgb2ycbcr_addmat = [0, 128, 128];

%     parfor c = 1:cc
%         for r = 1:rr
%             rgb_t = reshape(rgb(r, c, :), 1, []);  % reshape(mat,1,[]), [] equal numel(x)
%             rgb_t = double(rgb_t);
%             ycbcr_t = rgb_t * rgb2ycbcr_mat + rgb2ycbcr_addmat;
%             ycbcr(r, c, :) = (ycbcr_t);
%             % ycbcr(r, c, :) = ycbcr_t;
%         end
%     end

%     ycbcr = uint8(ycbcr);
% end

% 注：以上是自己写的；以下是根据matlab的库修改的。由于matlab库内rgb2ycbcr出来范围�?16-255，需求是0-255；但是matlab这个写法运算速度非常快，所以搬过来修改转换矩阵，让输出和上面自己写的结果相等�?

function ycbcr = jpeg_rgb2ycbcr(varargin)

    rgb = parse_inputs(varargin{:});

    % Initialize variables
    isColormap = false;

    % Must reshape colormap to be m x n x 3 for transformation
    if ismatrix(rgb)
        %colormap
        isColormap = true;
        colors = size(rgb, 1);
        rgb = reshape(rgb, [colors 1 3]);
    end

    % This matrix comes from a formula in Poynton's, "Introduction to
    % Digital Video" (p. 176, equations 9.6).

    % T is from equation 9.6: ycbcr = origT * rgb + origOffset;
    % origT = [ ...
    %     65.481 128.553 24.966;...
    %     -37.797 -74.203 112; ...
    %     112 -93.786 -18.214];
    origT = 255 * [0.299, 0.587, 0.114;
                -0.168736, -0.331264, 0.5;
                0.5, -0.418688, -0.081312
                ];
    origOffset = [0; 128; 128];

    % The formula ycbcr = origT * rgb + origOffset, converts a RGB image in the
    % range [0 1] to a YCbCr image where Y is in the range [16 235], and Cb and
    % Cr are in that range [16 240]. For each class type, we must calculate
    % scaling factors for origT and origOffset so that the input image is
    % scaled between 0 and 1, and so that the output image is in the range of
    % the respective class type.

    scaleFactor.float.T = 1/255; % scale output so in range [0 1].
    scaleFactor.float.offset = 1/255; % scale output so in range [0 1].
    scaleFactor.uint8.T = 1/255; % scale input so in range [0 1].
    scaleFactor.uint8.offset = 1; % output is already in range [0 255].
    scaleFactor.uint16.T = 257/65535; % scale input so it is in range [0 1]
    % and scale output so it is in range
    % [0 65535] (255*257 = 65535).
    scaleFactor.uint16.offset = 257; % scale output so it is in range [0 65535].

    % The formula ycbcr = origT*rgb + origOffset is rewritten as
    % ycbcr = scaleFactorForT * origT * rgb + scaleFactorForOffset*origOffset.
    % To use imlincomb, we rewrite the formula as ycbcr = T * rgb + offset, where T and
    % offset are defined below.
    if isfloat(rgb)
        classIn = 'error';
    else
        classIn = class(rgb);
    end
    T = scaleFactor.(classIn).T * origT;
    offset = scaleFactor.(classIn).offset * origOffset;

    % Initialize output
    ycbcr = zeros(size(rgb), 'like', rgb);

    for p = 1:3
        ycbcr(:, :, p) = imlincomb(T(p, 1), rgb(:, :, 1), T(p, 2), rgb(:, :, 2), ...
            T(p, 3), rgb(:, :, 3), offset(p));
    end

    if isColormap
        ycbcr = reshape(ycbcr, [colors 3 1]);
    end
end

%%%
%Parse Inputs
%%%
function X = parse_inputs(varargin)

    narginchk(1, 1);
    X = varargin{1};

    if ismatrix(X)
        % For backward compatibility, this function handles uint8 and uint16
        % colormaps. This usage will be removed in a future release.

        validateattributes(X, {'uint8', 'uint16', 'single', 'double'}, ...
            {'nonempty', 'real'}, mfilename, 'MAP', 1);
        if (size(X, 2) ~= 3 || size(X, 1) < 1)
            error(message('images:rgb2ycbcr:invalidSizeForColormap'));
        end
        if ~isfloat(X)
            warning(message('images:rgb2ycbcr:notAValidColormap'));
            X = im2double(X);
        end
    elseif (ndims(X) == 3)
        validateattributes(X, {'uint8', 'uint16', 'single', 'double'}, {'real'}, ...
            mfilename, 'RGB', 1);
        if (size(X, 3) ~= 3)
            error(message('images:rgb2ycbcr:invalidTruecolorImage'));
        end
    else
        error(message('images:rgb2ycbcr:invalidInputSize'))
    end
end
