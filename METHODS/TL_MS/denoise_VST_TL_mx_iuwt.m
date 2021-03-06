function [img_denoise, time] = denoise_VST_TL_mx_iuwt(img_raw,Iss_tl,sparsity_controller)
    
    
    if nargin<3
        sparsity_controller = -1;
    end
    
    fprintf('Denoising operation starts\n');
    
    %% estimate the noise of raw image
    fitparams = estimate_noise(img_raw);
    a = fitparams(1);
    b = fitparams(2);
    if a<0
        a = eps;
    end
    if b<0
        b = eps;
    end
    sigma = sqrt(b);
    
    
    t0=clock;  

    %%  apply forward variance stabilizing transformation
    fz = GenAnscombe_forward(img_raw, sigma, a, 0);
    sigma_den = 1; % Standard-deviation value assumed after variance-stabiliation
    
    % scale the transformed image to [0, 1]
    scale_range = 1;
    scale_shift = (1-scale_range)/2;
    maxzans = max(fz(:));
    minzans = min(fz(:));
    fz = (fz-minzans)/(maxzans-minzans);   sigma_den = sigma_den/(maxzans-minzans);
    fz = fz*scale_range+scale_shift;      sigma_den = sigma_den*scale_range;
    
    %% perform denoising algorithm on transformed images
    
    n = 121;
    
    if isempty(Iss_tl)    
        [Iss_tl,~,~] = TLdenoising_3(fz*255,sigma_den*255,n);
    end

    wname = 'dmey';
    [out,~] = TLdenoising_MS_N1(fz*255,sigma_den*255,n,wname,1);
%     N = 1;
%     [D,~] = change_A1_band_DWT(Iss_tl,out.A1h,wname,1); 
    D = fuse_bands_IUWT(Iss_tl,out.Ims_tl,1);
    
    D = D/255;
    % Scale back to the initial VST range
    D = (D-scale_shift)/scale_range;
    D = D*(maxzans-minzans)+minzans;
    
    %%  apply the inverse VST transform
    img_denoise = GenAnscombe_inverse_exact_unbiased(D, sigma, a, 0);   % exact unbiased inverse

    time = etime(clock, t0);
    
    fprintf('Denoising operation ends\n');
end