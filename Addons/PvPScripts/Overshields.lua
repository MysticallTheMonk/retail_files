local ABSORB_GLOW_ALPHA = 0.6;
local ABSORB_GLOW_OFFSET = -5;

hooksecurefunc("UnitFrame_Update",
	function(frame)
		local absorbBar = frame.totalAbsorbBar;
		if ( not absorbBar or absorbBar:IsForbidden()  ) then return end
		
		local absorbOverlay = frame.totalAbsorbBarOverlay;
		if ( not absorbOverlay or absorbOverlay:IsForbidden() ) then return end
		
		local healthBar = frame.healthbar;
		if ( not healthBar or healthBar:IsForbidden() ) then return end
		
		absorbOverlay:SetParent(healthBar);
		absorbOverlay:ClearAllPoints();		--we'll be attaching the overlay on heal prediction update.
	  	
	  	local absorbGlow = frame.overAbsorbGlow;
	  	if ( absorbGlow and not absorbGlow:IsForbidden() ) then
			absorbGlow:ClearAllPoints();
			absorbGlow:SetPoint("TOPLEFT", absorbOverlay, "TOPLEFT", ABSORB_GLOW_OFFSET, 0);
		  	absorbGlow:SetPoint("BOTTOMLEFT", absorbOverlay, "BOTTOMLEFT", ABSORB_GLOW_OFFSET, 0);
		  	absorbGlow:SetAlpha(ABSORB_GLOW_ALPHA);
	  	end
	end
)

hooksecurefunc("CompactUnitFrame_UpdateAll",
	function(frame)
		local absorbBar = frame.totalAbsorb;
		if ( not absorbBar or absorbBar:IsForbidden()  ) then return end
		
		local absorbOverlay = frame.totalAbsorbOverlay;
		if ( not absorbOverlay or absorbOverlay:IsForbidden() ) then return end
		
		local healthBar = frame.healthBar;
		if ( not healthBar or healthBar:IsForbidden() ) then return end
		
		absorbOverlay:SetParent(healthBar);
		absorbOverlay:ClearAllPoints();		--we'll be attaching the overlay on heal prediction update.
		
		local absorbGlow = frame.overAbsorbGlow;
	  	if ( absorbGlow and not absorbGlow:IsForbidden() ) then
			absorbGlow:ClearAllPoints();
			absorbGlow:SetPoint("TOPLEFT", absorbOverlay, "TOPLEFT", ABSORB_GLOW_OFFSET, 0);
		  	absorbGlow:SetPoint("BOTTOMLEFT", absorbOverlay, "BOTTOMLEFT", ABSORB_GLOW_OFFSET, 0);
		  	absorbGlow:SetAlpha(ABSORB_GLOW_ALPHA);
	  	end
	end
)

hooksecurefunc("UnitFrameHealPredictionBars_Update",
	function(frame)
		local absorbBar = frame.totalAbsorbBar;
		if ( not absorbBar or absorbBar:IsForbidden()  ) then return end
		
		local absorbOverlay = frame.totalAbsorbBarOverlay;
		if ( not absorbOverlay or absorbOverlay:IsForbidden() ) then return end
		
		local healthBar = frame.healthbar;
		if ( not healthBar or healthBar:IsForbidden() ) then return end
		
		local _, maxHealth = healthBar:GetMinMaxValues();
		if ( maxHealth <= 0 ) then return end
		
		local totalAbsorb = UnitGetTotalAbsorbs(frame.unit) or 0;
		if( totalAbsorb > maxHealth ) then
			totalAbsorb = maxHealth;
		end
				
		if( totalAbsorb > 0 ) then	--show overlay when there's a positive absorb amount
			if ( absorbBar:IsShown() ) then		--If absorb bar is shown, attach absorb overlay to it; otherwise, attach to health bar.
		  		absorbOverlay:SetPoint("TOPRIGHT", absorbBar, "TOPRIGHT", 0, 0);
		  		absorbOverlay:SetPoint("BOTTOMRIGHT", absorbBar, "BOTTOMRIGHT", 0, 0);
			else
				absorbOverlay:SetPoint("TOPRIGHT", healthBar, "TOPRIGHT", 0, 0);
	    		absorbOverlay:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", 0, 0);	    			
			end

			local totalWidth, totalHeight = healthBar:GetSize();			
			local barSize = totalAbsorb / maxHealth * totalWidth;
			
			absorbOverlay:SetWidth( barSize );
    		absorbOverlay:SetTexCoord(0, barSize / absorbOverlay.tileSize, 0, totalHeight / absorbOverlay.tileSize);
		  	absorbOverlay:Show();			
		  		
			--frame.overAbsorbGlow:Show();	--uncomment this if you want to ALWAYS show the glow to the left of the shield overlay
		end

	end
)

hooksecurefunc("CompactUnitFrame_UpdateHealPrediction",
	function(frame)
		local absorbBar = frame.totalAbsorb;
		if ( not absorbBar or absorbBar:IsForbidden()  ) then return end
		
		local absorbOverlay = frame.totalAbsorbOverlay;
		if ( not absorbOverlay or absorbOverlay:IsForbidden() ) then return end
		
		local healthBar = frame.healthBar;
		if ( not healthBar or healthBar:IsForbidden() ) then return end
		
		local _, maxHealth = healthBar:GetMinMaxValues();
		if ( maxHealth <= 0 ) then return end
		
		local totalAbsorb = UnitGetTotalAbsorbs(frame.displayedUnit) or 0;
		if( totalAbsorb > maxHealth ) then
			totalAbsorb = maxHealth;
		end
		
		if( totalAbsorb > 0 ) then	--show overlay when there's a positive absorb amount
			if ( absorbBar:IsShown() ) then		--If absorb bar is shown, attach absorb overlay to it; otherwise, attach to health bar.
		  		absorbOverlay:SetPoint("TOPRIGHT", absorbBar, "TOPRIGHT", 0, 0);
		  		absorbOverlay:SetPoint("BOTTOMRIGHT", absorbBar, "BOTTOMRIGHT", 0, 0);
			else
				absorbOverlay:SetPoint("TOPRIGHT", healthBar, "TOPRIGHT", 0, 0);
	    		absorbOverlay:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", 0, 0);	    			
			end

			local totalWidth, totalHeight = healthBar:GetSize();			
			local barSize = totalAbsorb / maxHealth * totalWidth;
			
			absorbOverlay:SetWidth( barSize );
    		absorbOverlay:SetTexCoord(0, barSize / absorbOverlay.tileSize, 0, totalHeight / absorbOverlay.tileSize);
		  	absorbOverlay:Show();
		  	
		  	--frame.overAbsorbGlow:Show();	--uncomment this if you want to ALWAYS show the glow to the left of the shield overlay
		end		
	end
)
