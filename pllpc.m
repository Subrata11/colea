function pllpc(t0)

% 绘制/更新LPC谱窗体
% Copyright (c) 1995 by Philipos C. Loizou
%

global fFig tFig filename Srate fno nLPC   nChannels UpperFreq
global HDRSIZE center LPCSpec Dur filterA filterB Lfreq
global OVRL ymin ymax  clrCnt bl al ymin2 ymax2 WAV1 chrCnt lnCnt
global TWOFILES TOP filename2 HDRSIZE2 Srate2
global al2 bl2 filterA2 filterB2 DiffSrate wav prM
global  FIX_SCALE yMAX yMIN
global ftype ftype2 bpsa bpsa2 ctlFig MAPLaw
global ipk1 ipk2 ipk3 iapk1 iapk2 iapk3 iengy plt_type LPC_ONLY
global FFT_SET pFFT lpcParam fft_par SET_X_AXIS F_MAX x_max 
global XFFT XFFT_TIMES
global foha fore
global fftFreqs dBMag
global fb_sav   % used for saving the coeffs in a file
global oha ore opy opn ope

fftSize=512;

clr='ymcrgbw';  % 颜色定义define all  colors 'y'=yellow, 'm'=magenta ,etc
chr='ox*+';
lns='-:-.--';

pos = get(0, 'screensize'); % get the screensize
sWi = pos(3);
sHe = pos(4);


wi=round(0.5625*sWi);
he=round(0.4*sHe);
le=round((sWi-wi)/2)-5;

sratef=Srate;

if isempty(plt_type), plt_type='line'; end;


	if TWOFILES==1 & TOP==1
		fname=filename2;
		hdrs =HDRSIZE2;	
		nSamples=round(Dur*Srate2/1000);
		sratef=Srate2;
		bps=bpsa2;	% Bits per sample
		ftp=ftype2;
	else
		fname=filename;
		hdrs =HDRSIZE;	
		nSamples=round(Dur*Srate/1000);
		bps=bpsa;  % Bits per sample
		ftp=ftype;
	end
	
	fp = fopen(fname,'r');
	if fp<=0
	  error('无法打开输入的文件');
	end
	

	offSet = t0*bps+hdrs;
	st = fseek(fp,offSet,'bof');
	
	inp = fread(fp,nSamples,ftp);
	[inp,ncount] = fread(fp,nSamples,ftp);
	if ncount<nSamples, nSamples=ncount;  
	end;
	if nSamples<20, 
	  fprintf('\n画LPC谱时出现错误. 窗口过小..\n\n');
	  fclose(fp); return;
	end
	
	fclose(fp);
   
%----------- 消除直流分量 ------------
meen=mean(inp);
inp=inp-meen;


%---- 对信号等级进行错误检查 ---
%---- Do some error checking on the signal level ---
if norm(inp,2) < 1.0e-7
  if meen < 1.0e-3
	meen=1.0e-3;
   end
   inp=inp+meen;
  engy=-100;
else
  engy=10*log10(norm(inp,2)^2);
end


if ~isempty(fFig) 
  invalid=0;
  eval('findobj(fFig);','invalid=1;');  
end

if  isempty(fFig) | invalid==1
	fFig = figure('Units', 'pixels', 'Position', [le 35 wi he],...
	'Menubar','None','NumberTitle','off','Name',...
	'LPC Spectra','WindowButtonDownFcn','puttext',...
	'Pointer','crosshair','Color','k');

else
	figure(fFig);

end

%---- 绘制控制窗体 ------------
if isempty(ctlFig) 
 drawctls;
end




% --检查帧数大于傅里叶变换采样数

if FFT_SET == 1 
    fftSize= pFFT;
    if nSamples>fftSize
      errordlg('帧数大于傅里叶变换采样数','WARNING','on');
    end
else

 if nSamples>fftSize
    fftSize=2*fftSize;
    if nSamples>fftSize, fftSize=2*fftSize; end
 end
end


if XFFT==1  % change the size of the FFT
   fftSize=fftSize*XFFT_TIMES;
end


fft2=fftSize/2;


%----------------- 绘制LPC频谱图 ----------------
if (LPCSpec == 1)   
     inpLP=inp;
     if lpcParam(2)==1  % use 1-st order pre-emphasis filter
        inpLP=filter([1 -0.95],[1],inp);      
         if lpcParam(1)==1
           inpLP=hamming(nSamples).*inpLP;  % Use hamming window
        end
     else % do not use pre-emphasis filter
       if lpcParam(1)==1
          inpLP=hamming(nSamples).*inp;    % Use hamming window
       end
     end
     
     
     [a,rxx] = ilpc(inpLP,nLPC);  % do LPC analysis
     Gain = rxx*a;  % LPC gain
     
     %if lpcParam(3)==1, a(2:nLPC+1)=((1.1).^[1:nLPC]).*a(2:nLPC+1);  end
	
    [H,F]= freqz(sqrt(Gain),a,fftSize,sratef);

else                		%--------------- Plot the FFT Spectrum ---------------
    fftFreqs = (0:fft2-1)/fftSize*sratef;
    fd=zeros(fftSize,1);
    if fft_par(2)==1 % use hamming window
       fd(1:nSamples)=hamming(nSamples).*inp;
    else  % use rectangular window
       fd(1:nSamples)=inp;
    end
    fd2= abs(fft((fd)));   
    fftMag = fd2(1:fft2);  
    if fftMag(1)<1E-8, fftMag(1)=fftMag(2)/10; end; % avoid log(0)
    dBMag = 20*log10(fftMag);  
end

    if (LPCSpec==1)
       fftFreqs = 0.5*(0:fftSize-1)/fftSize*sratef;
       fftMag=abs(H);
       dBMag = 20*log10(fftMag);
    end
    
    if OVRL<0
       hold on
	
	mb2=min(dBMag); mx2=max(dBMag); % -- LPC plot
	if (mb2 < ymin2), ymin2=mb2; end;
	if (mx2 > ymax2), ymax2=mx2; end;
	clrCnt=clrCnt+1;
	chrCnt=chrCnt+1;
	lnCnt=lnCnt+1;
	if lnCnt>2
     	   sclr= [lns(lnCnt:lnCnt+1)];
     	   lnCnt=lnCnt+1;
    	else
     	   sclr=[lns(lnCnt)];
    	end
	if (clrCnt==8), clrCnt=1; end;
	if (chrCnt==5), chrCnt=1; end;  
	if (lnCnt==6),  lnCnt=0; end;  
    else
		ymin2=min(dBMag); ymax2=max(dBMag);
	clrCnt=2; chrCnt=1; 
	lnCnt=1;
	sclr='-';
	hold off
    end
	

    if LPC_ONLY==0, subplot(2,1,1); 
    else	    subplot(1,1,1); end;

    if (OVRL<0), hold on, else hold off, end;
    set(gca,'LineStyleOrder',sclr);
   
    if LPCSpec==1
      h=plot(fftFreqs,dBMag);
      set(h,'color',clr(clrCnt));
   else
      if fft_par(1)==1, h=plot(fftFreqs,dBMag); set(h,'color',clr(clrCnt));
	else	
	   len=length(dBMag); db2=zeros(len,1); db3=zeros(len,1);
    	   db2(1)=dBMag(1);
    	   db2(2:len)=dBMag(1:len-1);
    	   db3(1:len-1)=dBMag(2:len); db3(len)=dBMag(len);
    	   ipks=find((dBMag > db2) & (dBMag > db3));
    	   rsl=sratef/fftSize; 
    	   pks=(ipks-1)*rsl; 

	   stem(pks,dBMag(ipks)); %-- plot only the peaks (harmonics)

	end
    end
     set(gca,'FontSize',9);
     set(gca,'Color','k');
     set(gca,'Xcolor','w'); 
     set(gca,'Ycolor','w');

 %
 %------- 寻找共振峰并显示数值 ---------------
 % 
 if LPCSpec==1
    len=length(dBMag); db2=zeros(len,1); db3=zeros(len,1);
    db2(1)=dBMag(1);
    db2(2:len)=dBMag(1:len-1);
    db3(1:len-1)=dBMag(2:len); db3(len)=dBMag(len);
    ipks=find((dBMag > db2) & (dBMag > db3));
    rsl=0.5*sratef/fftSize; 
    pks=(ipks-1)*rsl; pklen=length(ipks);
    if pklen>1, set(ipk1,'String',sprintf('%d',round(pks(1))));
	        set(iapk1,'String',sprintf('%d',round(dBMag(ipks(1))))); end;
    if pklen>2, set(ipk2,'String',sprintf('%d',round(pks(2)))); 
	        set(iapk2,'String',sprintf('%d',round(dBMag(ipks(2))))); end;
    if pklen>3, set(ipk3,'String',sprintf('%d',round(pks(3))));
  	        set(iapk3,'String',sprintf('%d',round(dBMag(ipks(3))))); 
	else
	        set(iapk3,'String','');  set(ipk3,'String','');end;
 else
	set(iapk1,'String','');  set(ipk1,'String','')
	set(iapk2,'String','');  set(ipk2,'String','')
	set(iapk3,'String','');  set(ipk3,'String','')
 end;
    set(iengy,'String',sprintf('%d',round(engy)));
	
 
    if LPC_ONLY==0 % top display=FFT or LPC 	
      axis([0 Lfreq ymin2 ymax2+3])
    else %----- single display of FFT or LPC spectrum

      x_max=sratef/2; 
      if SET_X_AXIS==1, if F_MAX< x_max, x_max=F_MAX; end; end;
      axis([0 x_max ymin2 ymax2+3])
      xlabel('频率(Hz)');
    end

    set(gca,'LineStyleOrder',sclr);
    h=ylabel('强度 (dB)');  set(h,'FontSize',9);

    set(gca,'FontSize',9); 
    
   


%------------ create the menus now ----------

if isempty(prM)
xywh = get(fFig, 'Position');

% Buttons.
left = 6;
wide = 40;
top  = xywh(4) - 3;
high = 22;
if 9*(22+8) > xywh(4), high=17; end;
inc  = high + 8;


%--------Set up the Print and Save Menu --------------


 prM=uimenu('Label','打印');
     uimenu(prM,'Label','Portrait模型','Callback','prnt2(''portr'')');
     uimenu(prM,'Label','Landscape图形','Callback','prnt2(''landsc'')');
 prM2= uimenu('Label','保存');
       uimenu(prM2,'Label','Black/White Postscript','Callback','prnt2(''bwps'')');
       uimenu(prM2,'Label','Color Postscript','Callback','prnt2(''ceps'')');
       uimenu(prM2,'Label','位映象','Callback','prnt2(''bmp'')');
       uimenu(prM2,'Label','Windows图元文件','Callback','prnt2(''wmf'')');
       uimenu(prM2,'Label','剪贴板','Callback','prnt2(''clip'')');

uil=uimenu('Label','标签');
	uimenu(uil,'Label','添加文本','Callback','itext(''add'')');
	uimenu(uil,'Label','删除文本','Callback','itext(''del'')');


optm=uimenu('Label','选项');
    	uf=uimenu(optm,'Label','设置频率范围');
		   uimenu(uf,'Label','默认','Callback','setpar(''range_def'')');
	 	   uimenu(uf,'Label','0-5 kHz','Callback','setpar(''range_5k'')');
		   uimenu(uf,'Label','0-4 kHz','Callback','setpar(''range_4k'')');
		   uimenu(uf,'Label','0-3.2 kHz','Callback','setpar(''range_32'')');

		oplp=uimenu(optm,'Label','LPC谱分析');
	   owi=uimenu(oplp,'Label','窗口');
		oha=uimenu(owi,'Label','汉明窗','Checked','on','Callback',...
			   'setovr(''LPhamming'')');
		ore=uimenu(owi,'Label','矩形窗','Callback',...
			   'setovr(''LPrect'')');
	   opr=uimenu(oplp,'Label','预加重');
		opn=uimenu(opr,'Label','否','Checked','on','Callback',...
			   'setovr(''LPnoPre'')');
		opy=uimenu(opr,'Label','是','Callback',...
			   'setovr(''LPyesPre'')');
		uimenu(oplp,'Label','在文件中储存LPC数据','Callback','savelpc');

 	opft=uimenu(optm,'Label','FFT分析');
		uimenu(opft,'Label','纠察谱','Callback','setpar(''FFT_pick'')');
	 	uimenu(opft,'Label','线性谱','Callback','setpar(''FFT_line'')');
			ufs=uimenu(opft,'Label','FFT 范围');
		   uimenu(ufs,'Label','默认','Callback','setpar(''size_def'')');
		   uimenu(ufs,'Label','x2','Callback','setpar(''size_x2'')');
         uimenu(ufs,'Label','x4','Callback','setpar(''size_x4'')'); 
         fowi=uimenu(opft,'Label','窗口');
         foha=uimenu(fowi,'Label','汉明窗','Checked','on','Callback',...
			   'setpar(''hamming'')');
         fore=uimenu(fowi,'Label','矩形窗','Callback',...
			   'setpar(''rect'')');


	
end

figure(fno);


