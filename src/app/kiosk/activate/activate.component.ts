import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { KioskService } from '../../core/services/kiosk.service';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-activate',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './activate.component.html',
  styleUrl: './activate.component.scss'
})
export class ActivateComponent implements OnInit {
  token: string = '';
  isLoading: boolean = false;
  errorMessage: string = '';

  constructor(
    private kioskService: KioskService,
    private router: Router
  ) { }

  ngOnInit() {
    // Check if already has token
    const existingToken = this.kioskService.getIslandToken();
    if (existingToken) {
      this.router.navigate(['/kiosk/checkin']);
    }
  }

  async activateIsland() {
    if (!this.token.trim()) {
      this.errorMessage = 'Por favor ingrese un token';
      return;
    }

    this.isLoading = true;
    this.errorMessage = '';

    const result = await this.kioskService.validateToken(this.token.trim());

    if (result.valid) {
      this.kioskService.setIslandToken(this.token.trim());
      this.router.navigate(['/kiosk/checkin']);
    } else {
      this.errorMessage = result.error || 'Token inválido';
    }

    this.isLoading = false;
  }

  onTokenInput(event: Event) {
    const input = event.target as HTMLInputElement;
    this.token = input.value;
    this.errorMessage = '';
  }

  navigateToAdmin() {
    this.router.navigate(['/admin']);
  }
}
