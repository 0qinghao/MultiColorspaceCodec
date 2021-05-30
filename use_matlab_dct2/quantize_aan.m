function out = quantize_aan(in, code)

    global divLumMatrix;
    global divChromMatrix;
    % global quantLumMatrix;
    % global quantChromMatrix;

    if strcmp(code, 'lum')
        index = 1;
        for i = 1:8
            for j = 1:8
                outputData(index) = round(in(i, j) * divLumMatrix(index));
                % outputData(index) = round(in(i, j) /  quantLumMatrix(index));
                index = index + 1;
            end
        end
    elseif strcmp(code, 'chrom')
        index = 1;
        for i = 1:8
            for j = 1:8
                outputData(index) = round(in(i, j) * divChromMatrix(index));
                % outputData(index) = round(in(i, j) /  quantChromMatrix(index));
                index = index + 1;
            end
        end
    end

    out = outputData;
end
