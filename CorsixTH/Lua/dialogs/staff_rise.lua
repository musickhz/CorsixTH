--[[ Copyright (c) 2010 Miika-Petteri Matikainen

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE. --]]

local math_floor
    = math.floor

-- Different complaint strings. All of them contain the rise amount.
-- In addition to that, some contain the final wage after the rise.
local texts = {
  _S(3, 4), -- "I'm totally frazzled. I need a good rest, plus a rise of  %d  if you don't want to see me jack in this poxy job."
  _S(3, 5), -- "I'm very tired. I need a rest and a salary boost of %d, putting me on %d. Do it now, you tyrant."
  _S(3, 6), -- "Come on. I'm working like a dog here. Give me a bonus of %d and I'll stay in your hospital."
  _S(3, 7), -- "I'm very unhappy. I demand a raise of %d, making my wages %d, otherwise I'm out of here."
  _S(3, 8), -- "My parents told me that the medical profession paid well. So give me a raise of %d or I'll become a computer games producer."
  _S(3, 9), -- "I'm fed up. Pay me a decent wage. I reckon a raise of %d should do the trick."
}

class "UIStaffRise" (Window)

function UIStaffRise:UIStaffRise(ui, staff, rise_amount)
  self:Window()
  local app = ui.app
  local profile = staff.profile

  self.esc_closes = false -- Do not allow closing the dialog with esc
  self.staff = staff
  self.ui = ui
  self.modal_class = "humanoid_info"
  self.rise_amount = rise_amount

  local final_wage = self.staff.profile.wage + rise_amount
  self.text = string.format(texts[math.random(1, #texts)], rise_amount, final_wage) -- Random complaint text

  self.width = 366
  self.height = 275

  -- Center the dialog
  self.x = app.config.width / 2 - self.width / 2
  self.y = app.config.height / 2 - self.height / 2

  self.panel_sprites = app.gfx:loadSpriteTable("QData", "Req12V", true)
  self.white_font = app.gfx:loadFont("QData", "Font01V")
  self.face_parts = app.gfx:loadRaw("Face01V", 65, 1350, "Data", "MPalette.dat")

  -- Left hand side
  self:addPanel(280, 0, 0)
  self:addPanel(281, 0, 54)
  self:addPanel(281, 0, 64)
  self:addPanel(281, 0, 64)
  self:addPanel(281, 0, 74)
  self:addPanel(281, 0, 84)
  self:addPanel(281, 0, 94)
  self:addPanel(281, 0, 104)
  self:addPanel(282, 0, 114)
  self:addPanel(283, 0, 171)
  self:addPanel(284, 0, 214)
  self:addColourPanel(96, 44, 72, 81, 211, 255, 255) -- Portrait background

  -- Right hand side
  self:addPanel(285, 180, 0)
  self:addPanel(286, 180, 20)
  self:addPanel(286, 180, 48)
  self:addPanel(286, 180, 76)
  self:addPanel(286, 180, 104)
  self:addPanel(286, 180, 132)
  self:addPanel(286, 180, 160)
  self:addPanel(287, 180, 188)
  self:addPanel(288, 180, 233):makeButton(0, 0, 90, 45, 289, self.increaseSalary) -- Increase salary button
  self:addPanel(290, 270, 233):makeButton(0, 0, 90, 45, 291, self.fireStaff) -- Fire button

  -- Hide doctor specific information
  if self.staff.profile.humanoid_class ~= "Doctor" then
    self:addColourPanel(10, 130, 160, 40, 60, 174, 203)
    self:addColourPanel(10, 198, 160, 45, 60, 174, 203)
  end
end

function UIStaffRise:getStaffPosition(dx, dy)
  local staff = self.staff
  local x, y = self.ui.app.map:WorldToScreen(staff.tile_x, staff.tile_y)
  local px, py = staff.th:getMarker()
  return x + px - (dx or 0), y + py - (dy or 0)
end

function UIStaffRise:draw(canvas)
  Window.draw(self, canvas)
  local profile = self.staff.profile
  local x, y = self.x, self.y
  local px, py = self:getStaffPosition(37, 61)
  local font = self.white_font

  profile:drawFace(canvas, x + 99, y + 47, self.face_parts) -- Portrait
  self.ui.app.map:draw(canvas, px, py, 71, 81, x + 16, y + 44) -- Viewport

  font:draw(canvas, profile.name, x + 20, y + 20) -- Name
  font:draw(canvas, "$" .. profile.wage, x + 60, y + 178) -- Wage

  if self.staff.profile.humanoid_class == "Doctor" then
    self:drawDoctorAttributes(canvas)
  end

  -- Complaint text
  font:drawWrapped(canvas, self.text, x + 200, y + 20, 140)
end

function UIStaffRise:drawDoctorAttributes(canvas)
  local profile = self.staff.profile
  local x, y = self.x, self.y

  -- Junior / Doctor / Consultant marker
  local marker_x = x + 98
  if profile.is_junior then
  elseif profile.is_consultant then
    marker_x = marker_x + 52
  else
    marker_x = marker_x + 22
  end

  self.panel_sprites:draw(canvas, 296, marker_x, y + 230)

  -- Ability markers
  if profile.is_surgeon then
    self.panel_sprites:draw(canvas, 292, x + 74, y + 133)
  end
  if profile.is_psychiatrist then
    self.panel_sprites:draw(canvas, 293, x + 90, y + 139)
  end
  if profile.is_researcher then
    self.panel_sprites:draw(canvas, 294, x + 120, y + 138)
  end

  -- Attention to detail
  local attention_bar_width = math.floor(profile.attention_to_detail * 40 + 0.5)
  if attention_bar_width ~= 0 then
    for dx = 0, attention_bar_width - 1 do
      self.panel_sprites:draw(canvas, 295, x + 42 + dx, y + 230)
    end
  end
end

function UIStaffRise:fireStaff()
  self.staff:fire()
  self:close()
end

function UIStaffRise:increaseSalary()
  self.staff:increaseWage(self.rise_amount)
  self:close()
end
