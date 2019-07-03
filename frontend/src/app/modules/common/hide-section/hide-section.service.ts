// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See doc/COPYRIGHT.rdoc for more details.
// ++


import {GonService} from "core-app/modules/common/gon/gon.service";
import {Injectable} from "@angular/core";
import {input} from "reactivestates";

export interface HideSectionDefinition {
  key:string;
  label:string;
}

@Injectable()
export class HideSectionService {
  public displayed = input<string[]>();
  public all:HideSectionDefinition[] = [];

  constructor(Gon:GonService) {
    const sections:any = Gon.get('hideSections');
    this.all = sections.all;
    this.displayed.putValue(sections.active.map((el:HideSectionDefinition) => el.key));
  }

  section(key:string):HTMLElement|null {
    return document.querySelector(`section.hide-section[data-section-name="${key}"]`);
  }

  hide(key:string) {
    this.displayed.doModify(displayed => displayed.filter(el => el !== key));
    this.toggleVisibility(key, true);
  }

  show(key:string) {
    this.displayed.doModify(displayed => [...displayed, key]);
    this.toggleVisibility(key, false);
  }

  private toggleVisibility(key:string, hidden:boolean) {
    const section = this.section(key);

    if (section) {
      section.hidden = hidden;
    }
  }
}
