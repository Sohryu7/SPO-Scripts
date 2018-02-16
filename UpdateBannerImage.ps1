#####
# Martin Surek
# 16.02.2018
# USAGE
#   UpdateBannerImage "Site Pages" 6 "/sites/ClassicTemplate/SiteAssets/Logo.jpg"
# REQS
#   SPO Management Shell + PnP Powershell Extensions, see https://github.com/SharePoint/PnP-PowerShell
#####

function UpdateBannerImage {
	param(
		[string]$listName,
		[int]$itemId,
		[string]$newBannerUrl
	)
	#get list item
	$item = Get-PnPListItem -List $listName -Id $itemId -Fields LayoutWebpartsContent, BannerImageUrl
	if($item["LayoutWebpartsContent"] -match 'data-sp-controldata="([^"]+)"'){
		# get substring w/ regex
		$temp = $item["LayoutWebpartsContent"] | Select-String -Pattern 'data-sp-controldata="([^"]+)"'
		$content = $temp.Matches.Groups[1].Value
		# replace [] bc sometimes it throws later
		$content = $content.replace("[","&#91;").replace("]","&#93;")
		# decode 
		$dec = [System.Web.HttpUtility]::HtmlDecode($content)
		# from JSON
		$jnContent = ConvertFrom-Json $dec
		
		#set values
		if (!$jnContent.serverProcessedContent) {
			$jnContent.serverProcessedContent = New-Object PSObject;
		}
		if (!$jnContent.serverProcessedContent.imageSources) {
			$jnContent.serverProcessedContent.imageSources = New-Object PSObject;
			$jnContent.serverProcessedContent.imageSources | add-member Noteproperty imageSource $newBannerUrl
		}
		if(!$jnContent.serverProcessedContent.imageSources.imageSource){
			$jnContent.serverProcessedContent.imageSources | add-member Noteproperty imageSource $newBannerUrl
		}
		$jnContent.serverProcessedContent.imageSources.imageSource = $newBannerUrl
		
		# need to always create new properties, otherwise nothing changes
		$curTitle = "";
		if($jnContent.properties){
			$curTitle = $jnContent.properties.title;
		}
        	$jnContent.properties = New-Object PSObject;
		$jnContent.properties | add-member Noteproperty title $curTitle
		$jnContent.properties | add-member Noteproperty imageSourceType 2
		
		# to JSON
		$newContent = $jnContent | ConvertTo-Json -Compress
		$enc = [System.Web.HttpUtility]::HtmlEncode($newContent)
		$enc = $enc.replace("{","&#123;").replace(":","&#58;").replace("}","&#125;").replace("[","&#91;").replace("]","&#93;")
		
		# replace full item property
		$fullContent = $item["LayoutWebpartsContent"].replace("[","&#91;").replace("]","&#93;");
		$fullContent = $fullContent -replace $content, $enc
		$fullContent.replace("&#91;","[").replace("&#93;","]")
		
		# set & update
		$item["LayoutWebpartsContent"] = $fullContent
		$item.Update()
		
		# not really sure if needed, but also update bannerURL
		Set-PnPListItem -List $listName -Id $itemId -Values @{"BannerImageUrl" = $newBannerUrl;}
	}
}
