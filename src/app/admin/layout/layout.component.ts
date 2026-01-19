import { Component, OnInit } from '@angular/core';
import { Router, RouterModule } from '@angular/router';
import { AuthService } from '../../core/services/auth.service';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-layout',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './layout.component.html',
  styleUrl: './layout.component.scss'
})
export class LayoutComponent implements OnInit {
  userEmail: string = '';

  constructor(
    private authService: AuthService,
    private router: Router
  ) { }

  ngOnInit() {
    const user = this.authService.currentUser;
    this.userEmail = user?.email || '';
  }

  async logout() {
    if (confirm('¿Está seguro que desea cerrar sesión?')) {
      await this.authService.signOut();
    }
  }

  navigateToKiosk() {
    this.router.navigate(['/kiosk/activate']);
  }
}
