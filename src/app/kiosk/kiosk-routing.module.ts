import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { ActivateComponent } from './activate/activate.component';
import { CheckinComponent } from './checkin/checkin.component';

const routes: Routes = [
  { path: '', redirectTo: 'activate', pathMatch: 'full' },
  { path: 'activate', component: ActivateComponent },
  { path: 'checkin', component: CheckinComponent }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class KioskRoutingModule { }
