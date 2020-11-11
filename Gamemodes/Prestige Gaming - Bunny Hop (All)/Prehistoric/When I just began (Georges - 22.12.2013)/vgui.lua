function PromptStringRequest( strTitle, strText, strDefaultText, fnEnter, fnCancel, strButtonText, strButtonCancelText )

	local Window = vgui.Create( "DFrame" )
		Window:SetTitle( strTitle or "Message Title (First Parameter)" )
		Window:SetDraggable( false )
		Window:ShowCloseButton( false )
		Window:SetBackgroundBlur( true )
		Window:SetDrawOnTop( true )
		
	local InnerPanel = vgui.Create( "DPanel", Window )
	
	local Text = vgui.Create( "DLabel", InnerPanel )
		Text:SetText( strText or "Message Text (Second Parameter)" )
		Text:SizeToContents()
		Text:SetContentAlignment( 5 )
		Text:SetTextColor( Color( 70, 70, 70, 255 ) )
		
	local TextEntry = vgui.Create( "DTextEntry", InnerPanel )
		TextEntry:SetText( strDefaultText or "" )
		TextEntry.OnEnter = function() Window:Close() fnEnter( TextEntry:GetValue() ) end
		
	local ButtonPanel = vgui.Create( "DPanel", Window )
	ButtonPanel:SetTall( 30 )
		
	local Button = vgui.Create( "DButton", ButtonPanel )
		Button:SetText( strButtonText or "OK" )
		Button:SizeToContents()
		Button:SetTall( 20 )
		Button:SetWide( Button:GetWide() + 20 )
		Button:SetPos( 5, 5 )
		Button.DoClick = function() Window:Close() fnEnter( TextEntry:GetValue() ) end
		
	local ButtonCancel = vgui.Create( "DButton", ButtonPanel )
		ButtonCancel:SetText( strButtonCancelText or "Cancel" )
		ButtonCancel:SizeToContents()
		ButtonCancel:SetTall( 20 )
		ButtonCancel:SetWide( Button:GetWide() + 20 )
		ButtonCancel:SetPos( 5, 5 )
		ButtonCancel.DoClick = function() Window:Close() if ( fnCancel ) then fnCancel( TextEntry:GetValue() ) end end
		ButtonCancel:MoveRightOf( Button, 5 )
		
	ButtonPanel:SetWide( Button:GetWide() + 5 + ButtonCancel:GetWide() + 10 )
	
	local w, h = Text:GetSize()
	w = math.max( w, 400 ) 
	
	Window:SetSize( w + 50, h + 25 + 75 + 10 )
	Window:Center()
	
	InnerPanel:StretchToParent( 5, 25, 5, 45 )
	
	Text:StretchToParent( 5, 5, 5, 35 )	
	
	TextEntry:StretchToParent( 5, nil, 5, nil )
	TextEntry:AlignBottom( 5 )
	
	TextEntry:RequestFocus()
	TextEntry:SelectAllText( true )
	
	ButtonPanel:CenterHorizontal()
	ButtonPanel:AlignBottom( 8 )
	
	Window:MakePopup()
	Window:DoModal()
	return Window

end


PANEL = {}

function PANEL:Init()

	self.List = vgui.Create("DPanelList", self)
	self.List:EnableVerticalScrollbar()
	self.List:SetPaintBackground(true)
	self.List:SetPadding(4)
	self.List:SetSpacing(1)
	self.List.Paint = function(w,h)
		draw.RoundedBox( 4, 0, 0, self.List:GetWide(), self.List:GetTall(), Color( 220, 220, 220, 255 ) )
		derma.SkinHook( "Paint", "PanelList", self.List, w, h )
	end

	self.CancelButton = vgui.Create("DButton", self)
	self.CancelButton:SetText("Cancel")
	self.CancelButton.DoClick = function(BTN) self:Close() end

end

function PANEL:PerformLayout()

	--derma.SkinHook( "Layout", "Frame", self )

	--Hacky copy paste from DFrame's PerformLayout()
	self.btnClose:SetPos( self:GetWide() - 31 - 4, 0 )
	self.btnClose:SetSize( 31, 31 )

	self.btnMaxim:SetPos( self:GetWide() - 31*2 - 4, 0 )
	self.btnMaxim:SetSize( 31, 31 )

	self.btnMinim:SetPos( self:GetWide() - 31*3 - 4, 0 )
	self.btnMinim:SetSize( 31, 31 )
	
	self.lblTitle:SetPos( 8, 2 )
	self.lblTitle:SetSize( self:GetWide() - 25, 20 )
	--end

	self.List:SetTall(200)
	
	self.CancelButton:SizeToContents()
	self.CancelButton:SetWide(self.CancelButton:GetWide() + 16)
	self.CancelButton:SetTall(self.CancelButton:GetTall() + 8)

	local height = 32
		
		height = height + self.List:GetTall()
		height = height + 8
		height = height + self.CancelButton:GetTall()
		height = height + 8

	self:SetTall(height)
	
	local width = self:GetWide()

	self.List:SetPos( 8, 32 )
	self.List:SetWide( width - 16 )
	
	local btnY = 32 + self.List:GetTall() + 8
	self.CancelButton:SetPos( width - 8 - self.CancelButton:GetWide(), btnY )
end

function PANEL:RemoveItem(BTN)
	self.List:RemoveItem(BTN)
	self:PerformLayout()
end

derma.DefineControl( "DSingleChoiceDialog", "A simple list dialog", PANEL, "DFrame" )

function PromptForChoice( TITLE, SELECTION, FUNCTION, ... )
	local arg = {...}
	local TE = vgui.Create("DSingleChoiceDialog")
	TE:SetBackgroundBlur( true )
	TE:SetDrawOnTop( true )
	for k,v in pairs(SELECTION) do
		local item = vgui.Create("DButton")
		item:SetText( v.Text )
		item.DoClick = 
			function(BTN) 
				TE.Selection = item
				pcall( FUNCTION, TE, v, unpack(arg) )
			end

		TE.List:AddItem(item)
	end
	TE:SetTitle(TITLE)
	TE:SetVisible( true )
	TE:SetWide(300)
	TE:PerformLayout()
	TE:Center()
	TE:MakePopup()

end