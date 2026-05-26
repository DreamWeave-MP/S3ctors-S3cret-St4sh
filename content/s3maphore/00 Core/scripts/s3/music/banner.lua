local isOpenMW = require 'scripts.s3.isOpenMW'
local ui, util, I, Constants

local bannerSizePct, BannerSize, SongBanner

if isOpenMW then
    ui = require 'openmw.ui'
    util = require 'openmw.util'
    I = require 'openmw.interfaces'
    Constants = require 'scripts.omw.mwui.constants'

    bannerSizePct = util.vector2(0.15, 0.08)
    BannerSize = ui.screenSize():emul(bannerSizePct)
else
    bannerSizePct = tes3vector2.new(0.15, 0.08)
    local ScreenW, ScreenH = tes3.getViewportSize()
    BannerSize = tes3vector2.new(ScreenW * bannerSizePct.x, ScreenH * bannerSizePct.y)
end

if isOpenMW then
    SongBanner = ui.create {
        layer = 'HUD',
        name = 'S3maphore_TrackBanner',
        template = I.MWUI.templates.boxTransparent,
        props = {
            relativePosition = util.vector2(0.5, 0),
            anchor = util.vector2(0.5, 0),
            visible = false,
        },
        content = ui.content {
            {
                name = 'SW4_CursorBannerText',
                template = I.MWUI.textHeader,
                type = ui.TYPE.Text,
                props = {
                    autoSize = false,
                    size = BannerSize,
                    text = '',
                    textColor = Constants.normalColor,
                    textSize = 18,
                    textAlignH = ui.ALIGNMENT.Center,
                    textAlignV = ui.ALIGNMENT.Center,
                    wordWrap = true,
                    multiline = true,
                }
            },
        }
    }
else
    local multi = tes3ui.findMenu('MenuMulti')
    SongBanner = multi:createRect{id = 'S3maphore_TrackBanner', color = {0, 0, 0}}
    SongBanner.autoWidth = true
    SongBanner.autoHeight = true
    SongBanner.absolutePosAlignX = 0.5
    SongBanner.absolutePosAlignY = 0
    SongBanner.alpha = 0.8

    local border = SongBanner:createThinBorder()
    border.widthProportional = 1
    border.heightProportional = 1

    local label = border:createLabel{id = 'SW4_CursorBannerText', text = ''}
    label.width = BannerSize.x
    label.height = BannerSize.y
    label.color = tes3ui.getPalette(tes3.palette.normalColor)
    label.justifyText = tes3.justifyText.center
    label.wrapText = true

    SongBanner.visible = false
end

return SongBanner
