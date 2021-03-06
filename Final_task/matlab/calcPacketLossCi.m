function calcPacketLossCi(maxNumberHttpUser, cctvOn, repeat)
%CALCPACKETLOSSCI Summary of this function goes here
%   Detailed explanation goes here

%   Daniel Ploeger, 2016/08/20 17:57:00
    
    %% Initialize variables.
    if nargin < 3 
        repeat = 10;            % Number of simulation runs with different seed
    end
    if nargin < 2
        cctvOn = 1;
    end
    if nargin < 1
        maxNumberHttpUser = 13;
    end
    
    warmupPeriod = 5;
    acceptableDelay = 0.1;  % 100 ms delay
    simTime = 5405;
    
    %% Loop over number of HTTP user
    videoConfDownload = cell(1,maxNumberHttpUser + 1);
    videoConfUpload = cell(1,maxNumberHttpUser + 1);
    cctv = cell(1,maxNumberHttpUser + 1);
    for i = 1 : maxNumberHttpUser + 1
%         if i - 1 < 10
%             path = strcat('0', num2str(i - 1), cctvPath);
%         else
%             path = strcat(num2str(i - 1), cctvPath);
%         end
        [videoConfDownload{i}, videoConfUpload{i}, cctv{i}] = qos(...
            i - 1, ...
            cctvOn, ...
            repeat, ...
            acceptableDelay, ...
            warmupPeriod);
    end
    
    
    %% Calculate confidence intervals
    videoConfDownloadCiLower(1:maxNumberHttpUser + 1) = double(NaN);
    videoConfDownloadCiHigher(1:maxNumberHttpUser + 1) = double(NaN);
    videoConfDownloadMean(1:maxNumberHttpUser + 1) = double(NaN);
    videoConfDownloadAvgDelay(1:maxNumberHttpUser + 1) = double(NaN);
    
    videoConfUploadCiLower(1:maxNumberHttpUser + 1) = double(NaN);
    videoConfUploadCiHigher(1:maxNumberHttpUser + 1) = double(NaN);
    videoConfUploadMean(1:maxNumberHttpUser + 1) = double(NaN);
    videoConfUploadAvgDelay(1:maxNumberHttpUser + 1) = double(NaN);
    
    cctvCiLower(1:maxNumberHttpUser + 1) = double(NaN);
    cctvCiHigher(1:maxNumberHttpUser + 1) = double(NaN);
    cctvMean(1:maxNumberHttpUser + 1) = double(NaN);
    cctvAvgDelay(1:maxNumberHttpUser + 1) = double(NaN);
    for i = 1:maxNumberHttpUser + 1
        [videoConfDownloadCiLower(i),videoConfDownloadCiHigher(i), ~] = confint2( ...
            videoConfDownload{i}.videoConfDownloadLossRate, str2double(i));
        videoConfDownloadMean(i) = mean(videoConfDownload{i}.videoConfDownloadLossRate);
        videoConfDownloadAvgDelay(i) = mean(videoConfDownload{i}.videoConfDownloadAvgDelay);
        
        [videoConfUploadCiLower(i),videoConfUploadCiHigher(i), ~] = confint2( ...
            videoConfUpload{i}.videoConfUploadLossRate, str2double(i));
        videoConfUploadMean(i) = mean(videoConfUpload{i}.videoConfUploadLossRate);
        videoConfUploadAvgDelay(i) = mean(videoConfUpload{i}.videoConfUploadAvgDelay);
        
        [cctvCiLower(i),cctvCiHigher(i), ~] = confint2( ...
            cctv{i}.cctvLossRate, str2double(i));
        cctvMean(i) = mean(cctv{i}.cctvLossRate);
        cctvAvgDelay(i) = mean(cctv{i}.cctvAvgDelay);
    end
    
    %% Calculate average FTP upload
    ftpLower(1:maxNumberHttpUser + 1) = double(NaN);
    ftpHigher(1:maxNumberHttpUser + 1) = double(NaN);
    ftpMean(1:maxNumberHttpUser + 1) = double(NaN);
    for i = 1:maxNumberHttpUser + 1
        ftpSentPkSum = importSca('University.whostFTP.tcpApp[0]', 'sentPk:sum(packetBytes)', i - 1, cctvOn, repeat);
        ftpUpload = ftpSentPkSum / (simTime - warmupPeriod);
        [ftpLower(i), ftpHigher(i), ~] = confint2(ftpUpload, str2double(i));
        ftpMean(i) = mean(ftpUpload);
    end
    % Convert to kbit/s
    ftpLower = ftpLower * 8 / 1000;
    ftpHigher = ftpHigher * 8 / 1000;
    ftpMean = ftpMean * 8 / 1000;
    
    %% Calculate average download per HTTP user
    httpLower(1:maxNumberHttpUser) = double(NaN);
    httpHigher(1:maxNumberHttpUser) = double(NaN);
    httpMean(1:maxNumberHttpUser) = double(NaN);
    % For current amount of users
    for i = 1:maxNumberHttpUser
        % For each user
        httpRcvdPkSum(1:i, 1:repeat) = double(NaN);
        for j = 1:i
            httpRcvdPkSum(j, :) = importSca(strcat('University.whttpStudents[', num2str(j - 1), '].tcpApp[0]'), ...
            'rcvdPk:sum(packetBytes)', i, cctvOn, repeat);
        end
        httpDownload = mean(httpRcvdPkSum, 1) / (simTime - warmupPeriod);
        [httpLower(i), httpHigher(i), ~] = confint2(httpDownload, str2double(i));
        httpMean(i) = mean(httpDownload);
    end    
    % Convert to kbit/s
    httpLower = httpLower * 8 / 1000;
    httpHigher = httpHigher * 8 / 1000;
    httpMean = httpMean * 8 / 1000;
    
    %% Calculate main router packet drops per HTTP user
    mRouterDropLower(1:maxNumberHttpUser + 1) = double(NaN);
    mRouterDropHigher(1:maxNumberHttpUser + 1) = double(NaN);
    mRouterDropMean(1:maxNumberHttpUser + 1) = double(NaN);
    for i = 1:maxNumberHttpUser + 1
        mRouterDrop = importSca('University.mainR.ppp[0].queue', 'dropPk:sum(packetBytes)', i - 1, cctvOn, repeat);
        mRouterDropPerSec = mRouterDrop / (simTime - warmupPeriod);
        [mRouterDropLower(i), mRouterDropHigher(i), ~] = confint2(mRouterDropPerSec, str2double(i));
        mRouterDropMean(i) = mean(mRouterDropPerSec);
    end
    % Convert to kbit/s
    mRouterDropLower = mRouterDropLower * 8 / 1000;
    mRouterDropHigher = mRouterDropHigher * 8 / 1000;
    mRouterDropMean = mRouterDropMean * 8 / 1000;
    
    %% Calculate remote router packet drops per HTTP user
    rRouterDropLower(1:maxNumberHttpUser + 1) = double(NaN);
    rRouterDropHigher(1:maxNumberHttpUser + 1) = double(NaN);
    rRouterDropMean(1:maxNumberHttpUser + 1) = double(NaN);
    for i = 1:maxNumberHttpUser + 1
        rRouterDrop = importSca('University.remoteR.ppp[0].queue', 'dropPk:sum(packetBytes)', i - 1, cctvOn, repeat);
        rRouterDropPerSec = rRouterDrop / (simTime - warmupPeriod);
        [rRouterDropLower(i), rRouterDropHigher(i), ~] = confint2(rRouterDropPerSec, str2double(i));
        rRouterDropMean(i) = mean(rRouterDropPerSec);
    end
    % Convert to kbit/s
    rRouterDropLower = rRouterDropLower * 8 / 1000;
    rRouterDropHigher = rRouterDropHigher * 8 / 1000;
    rRouterDropMean = rRouterDropMean * 8 / 1000;
    
    %% Plot
    plotXUpperBound = maxNumberHttpUser + 1;
    
    % Video conference download
    figure(1);
    plotYUpperBound = 0.075;
    plot (0:maxNumberHttpUser, videoConfDownloadAvgDelay, 'm')
    hold on
    plot([0 plotXUpperBound], [0.05 0.05], 'r')
    hold on
    for i = 1:maxNumberHttpUser + 1
        j = i - 1;
        plot([j j], [videoConfDownloadCiLower(i) videoConfDownloadCiHigher(i)], 'b', ...
            j, videoConfDownloadMean(i), 'xb');
        hold on
        if plotYUpperBound < videoConfDownloadCiHigher(i)
            plotYUpperBound = videoConfDownloadCiHigher(i) + 0.025;
        end
    end
    legend('Average Delay', 'Acceptable packet loss rate', 'Loss rate confidence interval', 'Loss rate mean', 'Location', 'northwest')
    title(strcat('Loss Rates and Average Delays of the Video Conference Download'))
    xlabel('Number of HTTP users web browsing simultaneously')
    ylabel('Packet loss rate / delay (s)')
    xlim([0 plotXUpperBound])
    ylim([0 plotYUpperBound])
    
    % Video conference upload
    figure(2);
    plotYUpperBound = 0.075;
    plot (0:maxNumberHttpUser, videoConfUploadAvgDelay, 'm')
    hold on
    plot([0 plotXUpperBound], [0.05 0.05], 'r')
    hold on
    for i = 1:maxNumberHttpUser + 1
        j = i - 1;
        plot([j j], [videoConfUploadCiLower(i) videoConfUploadCiHigher(i)], 'b', ...
            j, videoConfUploadMean(i), 'xb');
        hold on
        if plotYUpperBound < videoConfUploadCiHigher(i)
            plotYUpperBound = videoConfUploadCiHigher(i) + 0.025;
        end
    end
    plot([0 plotXUpperBound], [0.05 0.05], 'r')
    legend('Average Delay', 'Acceptable packet loss rate', 'Loss rate confidence interval', 'Loss rate mean', 'Location', 'northwest')
    title(strcat('Loss Rates and Average Delays of the Video Conference Upload'))
    xlabel('Number of HTTP users web browsing simultaneously')
    ylabel('Packet loss rate / delay (s)')
    xlim([0 plotXUpperBound])
    ylim([0 plotYUpperBound])
    
    % CCTV stream
    figure(3);
    plotYUpperBound = 0.075;
    plot (0:maxNumberHttpUser, cctvAvgDelay, 'm')
    hold on
    plot([0 plotXUpperBound], [0.05 0.05], 'r')
    hold on
    for i = 1:maxNumberHttpUser + 1
        j = i - 1;
        plot([j j], [cctvCiLower(i) cctvCiHigher(i)], 'b', ...
            j, cctvMean(i), 'xb');
        hold on
        if plotYUpperBound < cctvCiHigher(i)
            plotYUpperBound = cctvCiHigher(i) + 0.025;
        end
    end
    plot([0 plotXUpperBound], [0.05 0.05], 'r')
    legend('Average Delay', 'Acceptable packet loss rate', 'Loss rate confidence interval', 'Loss rate mean', 'Location', 'northwest')
    title(strcat('Loss Rates and Average Delays of the CCTV camera'))
    xlabel('Number of HTTP users web browsing simultaneously')
    ylabel('Packet loss rate / delay (s)')
    xlim([0 plotXUpperBound])
    ylim([0 plotYUpperBound])
    
    % FTP upload
    figure(4);
    for i = 1:maxNumberHttpUser + 1
        j = i - 1;
        plot([j j], [ftpLower(i) ftpHigher(i)], 'b', ...
            j, ftpMean(i), 'xb');
        hold on
    end
    legend('FTP upload confidence interval', 'FTP upload mean', 'Location', 'southeast')
    title(strcat('Average Upload Rate of FTP Connection'))
    xlabel('Number of HTTP users web browsing simultaneously')
    ylabel('kbit/s')
    ylim([0 inf])
    
    % HTTP download
    figure(5);
    for i = 1:maxNumberHttpUser
        plot([i i], [httpLower(i) httpHigher(i)], 'b', ...
            i, httpMean(i), 'xb');
        hold on
    end
    legend('HTTP download confidence interval', 'HTTP download mean', 'Location', 'southeast')
    title(strcat('Average Download Rate of Each Web Browsing User'))
    xlabel('Number of HTTP users web browsing simultaneously')
    ylabel('kbit/s')
    ylim([0 inf])
    
    % Main router
    figure(6);
    for i = 1:maxNumberHttpUser + 1
        j = i - 1;
        plot([j j], [mRouterDropLower(i) mRouterDropHigher(i)], 'b', ...
            j, mRouterDropMean(i), 'xb');
        hold on
    end
    legend('Packet drop confidence interval', 'Packet drop mean', 'Location', 'northwest')
    title(strcat('Radio Link Download Bytes Dropped (Main Router Output Queue)'))
    xlabel('Number of HTTP users web browsing simultaneously')
    ylabel('kbit/s')
    ylim([0 inf])
    
    % Remote router
    figure(7);
    for i = 1:maxNumberHttpUser + 1
        j = i - 1;
        plot([j j], [rRouterDropLower(i) rRouterDropHigher(i)], 'b', ...
            j, rRouterDropMean(i), 'xb');
        hold on
    end
    legend('Packet drop confidence interval', 'Packet drop mean', 'Location', 'northwest')
    title(strcat('Radio Link Upload Bytes Dropped (Remote Router Output Queue)'))
    xlabel('Number of HTTP users web browsing simultaneously')
    ylabel('kbit/s')
    ylim([0 inf])
end